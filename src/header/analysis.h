
#include <cuda_runtime.h>

typedef struct{
	short int device;
	short int style;
	short int threadPerBlock;
	double dt;
	char *sourceFile;
	char *outFile;
	int iteration;
	int targetFrame;
	double endtime;
}parameter;




typedef struct{
	cudaEvent_t start, stop;
	float elapsed_time;
}gpuTiming;


typedef struct{
	double start, stop;
	double elapsed_time;
}cpuTiming;

typedef struct{
	short int thread;
	int iteration;
	gpuTiming gCoreTime;
	cpuTiming cCoreTime;
	cpuTiming cVisualTime;
	unsigned int frame;
	double simulationTime;
}dataAnalysis;

double cpuSecond();
void gpuTimingStartRec(gpuTiming *GPUTiming);
void gpuTimingStopRec(gpuTiming *GPUTiming, float prevElapsed);

void cpuTimingStartRec(cpuTiming *CPUTiming);
void cpuTimingStopRec(cpuTiming *CPUTiming,float prevElapsed);



void initParam(parameter *Param);

void initAnalis(dataAnalysis *Analis);

void showAnalis(parameter P, dataAnalysis A);
