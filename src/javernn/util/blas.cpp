#include <math.h>
#include <assert.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "javernn/util/blas.h"

namespace javernn
{
    void mul_cpu(int N, float *X, int INCX, float *Y, int INCY)
    {
        int i;
        for(i = 0; i < N; ++i) Y[i*INCY] *= X[i*INCX];
    }

    void pow_cpu(int N, float ALPHA, float *X, int INCX, float *Y, int INCY)
    {
        int i;
        for(i = 0; i < N; ++i) Y[i*INCY] = pow(X[i*INCX], ALPHA);
    }

    void axpy_cpu(int N, float ALPHA, float *X, int INCX, float *Y, int INCY)
    {
        int i;
        for(i = 0; i < N; ++i) Y[i*INCY] += ALPHA*X[i*INCX];
    }

    void scal_cpu(int N, float ALPHA, float *X, int INCX)
    {
        int i;
        for(i = 0; i < N; ++i) X[i*INCX] *= ALPHA;
    }

    void fill_cpu(int N, float ALPHA, float *X, int INCX)
    {
        int i;
        for(i = 0; i < N; ++i) X[i*INCX] = ALPHA;
    }

    void copy_cpu(int N, float *X, int INCX, float *Y, int INCY)
    {
        int i;
        for(i = 0; i < N; ++i) Y[i*INCY] = X[i*INCX];
    }

    void mult_add_into_cpu(int N, float *X, float *Y, float *Z)
    {
        int i;
        for(i = 0; i < N; ++i) Z[i] += X[i]*Y[i];
    }

    void add_cpu(int N, float *X, int INCX, float *Y, int INCY)
    {
        int i;
        for(i = 0; i < N; ++i) Y[i*INCY] += X[i*INCX];
    }

    void softmax(float *input, int n, float temp, int stride, float *output)
    {
        int i;
        float sum = 0;
        float largest = -FLT_MAX;
        for(i = 0; i < n; ++i){
            if(input[i*stride] > largest) largest = input[i*stride];
        }
        for(i = 0; i < n; ++i){
            float e = exp(input[i*stride]/temp - largest/temp);
            sum += e;
            output[i*stride] = e;
        }
        for(i = 0; i < n; ++i){
            output[i*stride] /= sum;
        }
    }

    void softmax_cpu(float *input, int n, int batch, int batch_offset, int groups, int group_offset, int stride, float temp, float *output)
    {
        int g, b;
        for(b = 0; b < batch; ++b){
            for(g = 0; g < groups; ++g){
                softmax(input + b*batch_offset + g*group_offset, n, temp, stride, output + b*batch_offset + g*group_offset);
            }
        }
    }
} // namespace javernn




