/*Template was modified from NVIDIA Cuda Sample*/

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "header/header.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "user defined lib/vbo.h"
#include <timer.h>
#include <numeric>
#include <iostream>

#define REFRESH_DELAY     10 //ms

const char *Judul
	= "SIMULASI GELOMBANG AIR";

// Ukuran jendela layar
unsigned int window_width  = 2000;
unsigned int window_height = 1000;

// kontrol pada mouse
int mouse_old_x, mouse_old_y;
int mouse_buttons = 0;
float rotate_x = 0.0, rotate_y = 0.0;
float translate_z = -3.0;
float translate_y = 0.0;
float translate_x = 0.0;
float translate_zz=0.0;

//variabel untuk keperluan analisis
//dan pencatatan waktu komputasi
parameter globalParam;
dataAnalysis Analis;

//Data-data komputasi dan visualisasi
GLuint shaderProg;
vbo VBO;
dataWaveCompute dataHost, dataDev;

//Variabel alokasi GPU
gpuThread GPUThread;
int STATUS=PAUSE;

void mainFlow()
{

	InitMesh(&dataHost.Mesh, "test.txt");

	InitDataComputation(&dataHost,globalParam.dt);

	if(globalParam.device==DEVICE_GPU)
	{
		GPUSimulationAllocationMemory(&dataDev, dataHost);
		threadAllocation(globalParam.threadPerBlock,
						&GPUThread,dataDev);
	}

    initVBO(&VBO,dataHost.Mesh);
    glutMainLoop();
}
void display()
{

    if(STATUS==RUNNING)
    {
    	Analis.frame++;
    	if(globalParam.device==DEVICE_GPU)
    	{
    		gpuTimingStartRec(&Analis.gCoreTime);
    		computeGPU(globalParam.iteration,GPUThread,&dataDev);
    		gpuTimingStopRec(&Analis.gCoreTime, Analis.gCoreTime.elapsed_time);
    		Analis.simulationTime+=dataDev.dt*globalParam.iteration;

    	}else
    	{
    		cpuTimingStartRec(&Analis.cCoreTime);
    		computeCPU(globalParam.iteration, &dataHost);
    		cpuTimingStopRec(&Analis.cCoreTime, Analis.cCoreTime.elapsed_time);
    		Analis.simulationTime+=dataHost.dt*globalParam.iteration;
    	}

    }

    if(!(globalParam.style==STYLE_NOVISUALIZATION))
    {

		computeVisualization(VBO,globalParam,GPUThread,&dataDev,dataHost);

//kontrol layar openGL
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glTranslatef(0.0, 0.0, translate_z);//-3.25);
		glRotatef(rotate_x+5, 1.0, 0.0, 0.0);
		glRotatef(rotate_y -5, 0.0, 1.0, 0.0);
		glTranslatef(-0.5 + translate_x, -0.5, 0.75+translate_y);

		renderingVBO(shaderProg, VBO,dataDev,globalParam);
    }

    if(STATUS==RUNNING)
		if(timesUp(globalParam.endtime,Analis.simulationTime) ||
				frameOver(globalParam.targetFrame,Analis.frame))
		  {
			cpuTimingStopRec(&Analis.cVisualTime,Analis.cVisualTime.elapsed_time);
			STATUS=PAUSE;
		  }

    glutSwapBuffers();


}


int attachShader(GLuint prg, GLenum type, const char *name)
{
    GLuint shader;
    FILE *fp;
    int size, compiled;
    char *src;

    fp = fopen(name, "rb");

    if (!fp)
    {
        return 0;
    }

    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    src = (char *)malloc(size);

    fseek(fp, 0, SEEK_SET);
    fread(src, sizeof(char), size, fp);
    fclose(fp);

    shader = glCreateShader(type);
    glShaderSource(shader, 1, (const char **)&src,
    		(const GLint *)&size);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS,
    		(GLint *)&compiled);

    if (!compiled)
    {
        char log[2048];
        int len;

        glGetShaderInfoLog(shader, 2048,
        		(GLsizei *)&len, log);
        printf("Info log: %s\n", log);
        glDeleteShader(shader);
        return 0;
    }

    free(src);

    glAttachShader(prg, shader);
    glDeleteShader(shader);

    return 1;
}

GLuint loadGLSLProgram(const char *vertFileName,
		const char *fragFileName)
{
    GLint linked;
    GLuint program;

    program = glCreateProgram();

    if (!attachShader(program, GL_VERTEX_SHADER, vertFileName))
    {
        glDeleteProgram(program);
        fprintf(stderr, "kesalahan attach vertek %s\n", vertFileName);
        return 0;
    }

    if (!attachShader(program, GL_FRAGMENT_SHADER, fragFileName))
    {
        glDeleteProgram(program);
        fprintf(stderr, "Ckesalahan attach fragment %s\n",
        		fragFileName);

        return 0;
    }

    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &linked);

    if (!linked)
    {
        glDeleteProgram(program);
        char temp[256];
        glGetProgramInfoLog(program, 256, 0, temp);
        fprintf(stderr, "Failed to link program: %s\n", temp);
        return 0;
    }

    return program;
}


double cpuSecond(){
	struct timeval tp;
	gettimeofday(&tp,NULL);
	return ((double)tp.tv_sec
			+ (double)tp.tv_usec*1.e-6);
}

void gpuTimingStartRec(gpuTiming *GPUTiming)
{

		cudaEventCreate( &GPUTiming->start) ;
		 cudaEventCreate( &GPUTiming->stop) ;
		 cudaEventRecord( GPUTiming->start, 0 ) ;
}
void gpuTimingStopRec(gpuTiming *GPUTiming,
		float prevElapsed)
{
		cudaEventRecord( GPUTiming->stop, 0 ) ;
		cudaEventSynchronize( GPUTiming->stop ) ;
		cudaEventElapsedTime( &GPUTiming->elapsed_time,
				GPUTiming->start, GPUTiming->stop ) ;
		cudaEventDestroy( GPUTiming->start ) ;
		cudaEventDestroy( GPUTiming->stop ) ;
		GPUTiming->elapsed_time/=1000;
		GPUTiming->elapsed_time+=prevElapsed;

}

void cpuTimingStartRec(cpuTiming *CPUTiming)
{
	CPUTiming->start=cpuSecond();

}
void cpuTimingStopRec(cpuTiming *CPUTiming,float prevElapsed)
{
	CPUTiming->stop=cpuSecond();
	CPUTiming->elapsed_time=CPUTiming->stop-CPUTiming->start
			+prevElapsed;
}




void initParam(parameter *Param)
{
	Param->device=DEVICE_GPU;
	Param->iteration=20;
	Param->style=STYLE_SURFACE;
	Param->endtime=100;
	Param->threadPerBlock=128;
	Param->targetFrame=-1;
	Param->dt=0.00075;

}

void initAnalis(dataAnalysis *Analis)
{
	Analis->frame=0;
	Analis->cVisualTime.elapsed_time=0;
	Analis->cCoreTime.elapsed_time=0;
	Analis->gCoreTime.elapsed_time=0;

	Analis->cVisualTime.stop=0;
	Analis->cCoreTime.stop=0;
	Analis->gCoreTime.stop=0;

	Analis->cVisualTime.start=0;
	Analis->cCoreTime.start=0;
	Analis->gCoreTime.start=0;

	Analis->simulationTime=0;
}

void showAnalis(parameter P, dataAnalysis A)
{
	printf("\n\n......Data Analisis.....\n");
	printf("\nThreadPerBlock\t\t: %d",P.threadPerBlock);
	printf("\nIterationPerFrame\t: %d",P.iteration);
	printf("\nFrame\t\t\t: %d",A.frame);
	printf("\nTotal Iteration\t\t: %d",
			P.iteration*(A.frame));
	printf("\nElapsed Time CPU\t: %0.3lf",
			A.cCoreTime.elapsed_time);
	printf("\nElapsed Time GPU\t: %0.3lf",
			A.gCoreTime.elapsed_time);
	if(P.style==STYLE_NOVISUALIZATION)
		A.cVisualTime.elapsed_time=0;
	printf("\nVisualization Time\t: %0.3lf",
			A.cVisualTime.elapsed_time);
	printf("\nSimulation Real Time\t: %0.3lf",
			A.simulationTime);
	printf("\n");
}



int timesUp( double endTime,double elapsedSimulation)
{
	return (elapsedSimulation>=endTime && endTime>0);

}

int frameOver( int targetFrame,int frame)
{	glVertex3f(1.02, 0.0,0.37);
	return (frame>=targetFrame && targetFrame>0);
}



void timerEvent(int value)
{
    if (glutGetWindow())
    {
        glutPostRedisplay();
        glutTimerFunc(REFRESH_DELAY, timerEvent,0);
    }
}

void cleanup()
{

  	 deleteVBO2(&VBO.posVertexBuffer);
  	 deleteVBO2(&VBO.VertexNormalBuffer);
  	 deleteVBO2(&VBO.signBuffer);

  	 GPUSimulationFreeMemory(&dataDev);
     showAnalis(globalParam,Analis);
     glutDestroyWindow(glutGetWindow());

     cudaDeviceReset();
}



void keyboard(unsigned char key, int /*x*/, int /*y*/)
{
    switch (key)
    {
    	case 13:
    		if(STATUS==PAUSE)
    		{
    			STATUS=RUNNING;
    			cpuTimingStartRec(&Analis.cVisualTime);
    		}else
    		{
    			STATUS=PAUSE;
    			cpuTimingStopRec(&Analis.cVisualTime,
    					Analis.cVisualTime.elapsed_time);
    		}
    			break;
        case (27) :
        		if(STATUS==RUNNING)
        				cpuTimingStopRec(&Analis.cVisualTime,
        						Analis.cVisualTime.elapsed_time);
            #if defined(__APPLE__) || defined(MACOSX)
                exit(EXIT_SUCCESS);
            #else


                glutLeaveMainLoop();
                return;
            #endif
    }
}

////////////////////////////////////////////////////////////////////////////////
//! Mouse event handlers
////////////////////////////////////////////////////////////////////////////////
void mouse(int button, int state, int x, int y)
{
	if (state == GLUT_DOWN && button==GLUT_MIDDLE_BUTTON)
	{
		mouse_buttons=2;

	}
	else if (state == GLUT_DOWN)
    {
        mouse_buttons |= 1<<button;
    }
    else if (state == GLUT_UP)
    {
        mouse_buttons = 0;
    }


    mouse_old_x = x;
    mouse_old_y = y;
}

void motion(int x, int y)
{
    float dx, dy;
    dx = (float)(x - mouse_old_x);
    dy = (float)(y - mouse_old_y);
    if (mouse_buttons & 1)
    {
        rotate_x += dy * 0.2f;
        rotate_y += dx * 0.2f;
    }
    else if (mouse_buttons & 4)
    {
        translate_z += dy * 0.01f;
    }
    else if (mouse_buttons ==2)
    {
    	translate_y += dy*0.01f;
    	translate_x += dx*0.01f;

    }
    mouse_old_x = x;
    mouse_old_y = y;
}


int main(int argc, char **argv)
{
    char *ref_string= NULL;

    initParam(&globalParam);
    initAnalis(&Analis);

#if defined(__linux__)
    setenv ("DISPLAY", ":0", 0);
#endif

    printf("%s starting...\n", Judul);

    if (argc > 1)
    {


        if (checkCmdLineFlag(argc, (const char **)argv, "frame"))
        {

            getCmdLineArgumentString(argc, (const char **)argv,
            		"frame", (char **)&ref_string);
            sscanf(ref_string,"%d",&globalParam.targetFrame);

        }

        if (checkCmdLineFlag(argc, (const char **)argv, "file"))
        {

            getCmdLineArgumentString(argc, (const char **)argv,
            		"file", (char **)&ref_string);
            printf("\nNama File : %s", ref_string);
            globalParam.sourceFile=ref_string;
        }
        if (checkCmdLineFlag(argc, (const char **)argv, "thread"))
		{

			getCmdLineArgumentString(argc, (const char **)argv,
					"thread", (char **)&ref_string);
			printf("\nNAlokasi Thread : %s", ref_string);
			sscanf(ref_string,"%d",&globalParam.threadPerBlock);
			printf("\nintThread : %d", globalParam.threadPerBlock);


		}
        if (checkCmdLineFlag(argc, (const char **)argv, "endtime"))
		{

			getCmdLineArgumentString(argc, (const char **)argv,
					"endtime", (char **)&ref_string);
			printf("\nEnd Time : %s", ref_string);
			sscanf(ref_string,"%lf",&globalParam.endtime);

		}
        if (checkCmdLineFlag(argc, (const char **)argv, "dt"))
		{

			getCmdLineArgumentString(argc, (const char **)argv,
					"dt", (char **)&ref_string);
			printf("\nTime Step : %s", ref_string);
			sscanf(ref_string,"%lf",&globalParam.dt);

		}
        if (checkCmdLineFlag(argc, (const char **)argv, "style"))
		{

			getCmdLineArgumentString(argc, (const char **)argv,
					"style", (char **)&ref_string);
			printf("Visual Style : %s", ref_string);
			if(strcmp(ref_string,"novisualization")==0)
			{
				globalParam.style=STYLE_NOVISUALIZATION;

			}else if(strcmp(ref_string,"surface")==0)
			{
				globalParam.style=STYLE_SURFACE;

			}else if(strcmp(ref_string,"hsv")==0)
			{
				globalParam.style=STYLE_COLORHSV;
			}
			else if(strcmp(ref_string,"wire")==0)
			 {
						globalParam.style=STYLE_WIRE;
			 }
			else
			{
				int tempInt;
				sscanf(ref_string,"%d",&tempInt);
				if(tempInt<3)
				{
					globalParam.style=tempInt;
				}
			}


		}
        if (checkCmdLineFlag(argc, (const char **)argv, "device"))
	   {

		   getCmdLineArgumentString(argc, (const char **)argv,
				   "device", (char **)&ref_string);
		   printf("\nPilihan Device: %s", ref_string);
		   if(strcmp(ref_string,"cpu")==0)
		   {
			   globalParam.device=DEVICE_CPU;
		   }else if (strcmp(ref_string,"gpu")==0)
		   {
			   globalParam.device=DEVICE_GPU;
		   }
	   }
        if (checkCmdLineFlag(argc, (const char **)argv, "iteration"))
	   {

		   getCmdLineArgumentString(argc, (const char **)argv,
				   "iteration", (char **)&ref_string);
		   printf("\nIterasi : %s", ref_string);
		   int tempInt;

			sscanf(ref_string,"%d",&tempInt);
			if(tempInt>0)
			{
				globalParam.iteration=tempInt;
			}
	   }
        if (checkCmdLineFlag(argc, (const char **)argv, "out"))
	   {

		   getCmdLineArgumentString(argc, (const char **)argv,
				   "out", (char **)&ref_string);
		   printf("\nOut file : %s", ref_string);
		   if(strcmp(ref_string,"")!=0)
		   {
			   globalParam.outFile=ref_string;
		   }
	   }
    }

    if(globalParam.style==STYLE_NOVISUALIZATION)
    {
    	STATUS=RUNNING;
    	printf("\nNO Visualization");
    	printf("\nProcess...");

    }

    runTest(argc, argv, NULL);//ref_string

}


bool initGL(int *argc, char **argv)
{
    glutInit(argc, argv);
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
    glutInitWindowSize(500, 500);
    glutCreateWindow("Cuda GL Interop (VBO)");
    glutFullScreen();
    glutDisplayFunc(display);
    glutKeyboardFunc(keyboard);
    glutMotionFunc(motion);
    glutTimerFunc(REFRESH_DELAY, timerEvent,0);

    char* vertShaderPath = sdkFindFilePath("test.vert", argv[0]);
    char* fragShaderPath = sdkFindFilePath("test.frag", argv[0]);
    // initialize necessary OpenGL extensions
    glewInit();

    if (! glewIsSupported("GL_VERSION_2_0 "))
    {
        fprintf(stderr, "ERROR: Support for necessary OpenGL extensions missing.");
        fflush(stderr);
        return false;
    }

    // default initialization
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glDisable(GL_DEPTH_TEST);
   // viewport
    glViewport(0, 0, window_width, window_height);

    // projection
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(60.0, (GLfloat)window_width / (GLfloat) window_height, 0.1, 10.0);
    shaderProg = loadGLSLProgram(vertShaderPath, fragShaderPath);
     SDK_CHECK_ERROR_GL();

    return true;
}

bool runTest(int argc, char **argv, char *ref_file)
{


    // command line mode only
    if (ref_file != NULL)
    {   printf("\nTEST");
        int devID = findCudaDevice(argc, (const char **)argv);

        cudaDeviceReset();
    }
    else		glVertex3f(1.02, 0.0,0.37);
    {

        if (false == initGL(&argc, argv))
        {
            return false;
        }

        if (checkCmdLineFlag(argc, (const char **)argv, "device"))
        {
            if (gpuGLDeviceInit(argc, (const char **)argv) == -1)
            {

                return false;
            }
        }
        else
        {

            cudaGLSetGLDevice(gpuGetMaxGflopsDeviceId());
        }
       // register callbacks
        glutDisplayFunc(display);
        glutKeyboardFunc(keyboard);
        glutMouseFunc(mouse);
        glutMotionFunc(motion);
#if defined (__APPLE__) || defined(MACOSX)
        atexit(cleanup);
#else
        glutCloseFunc(cleanup);
#endif

    			char Title[BUFSIZ];
    			sprintf(Title, "Mesh Dam Break/Mesh2D_14362.neu");

                mainFlow();




    }

    return true;
}


#ifdef _WIN32
#ifndef FOPEN
#define FOPEN(fHandle,filename,mode) fopen_s(&fHandle, filename, mode)
#endif
#else
#ifndef FOPEN
#define FOPEN(fHandle,filename,mode) (fHandle = fopen(filename, mode))
#endif
#endif

void sdkDumpBin2(void *data, unsigned int bytes, const char *filename)
{
    printf("sdkDumpBin: <%s>\n", filename);
    FILE *fp;
    FOPEN(fp, filename, "wb");
    fwrite(data, bytes, 1, fp);
    fflush(fp);
    fclose(fp);
}

