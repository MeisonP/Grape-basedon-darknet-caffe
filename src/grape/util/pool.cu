
namespace grape{

    __global__ void forward_maxpool_kernel(int n, int in_h, int in_w, int in_c, int stride, int size, int pad, float *input, float *output, int *indexes)
    {
        int h = (in_h + pad - size)/stride + 1;
        int w = (in_w + pad - size)/stride + 1;
        int c = in_c;

        int id = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
        if(id >= n) return;

        int j = id % w;
        id /= w;
        int i = id % h;
        id /= h;
        int k = id % c;
        id /= c;
        int b = id;

        int w_offset = -pad/2;
        int h_offset = -pad/2;

        int out_index = j + w*(i + h*(k + c*b));
        float max = -INFINITY;
        int max_i = -1;
        int l, m;
        for(l = 0; l < size; ++l){
            for(m = 0; m < size; ++m){
                int cur_h = h_offset + i*stride + l;
                int cur_w = w_offset + j*stride + m;
                int index = cur_w + in_w*(cur_h + in_h*(k + b*in_c));
                int valid = (cur_h >= 0 && cur_h < in_h &&
                        cur_w >= 0 && cur_w < in_w);
                float val = (valid != 0) ? input[index] : -INFINITY;
                max_i = (val > max) ? index : max_i;
                max   = (val > max) ? val   : max;
            }
        }
        output[out_index] = max;
        indexes[out_index] = max_i;
    }

    __global__ void backward_maxpool_kernel(int n, int in_h, int in_w, int in_c, int stride, int size, int pad, float *delta, float *prev_delta, int *indexes)
    {
        int h = (in_h + pad - size)/stride + 1;
        int w = (in_w + pad - size)/stride + 1;
        int c = in_c;
        int area = (size-1)/stride;

        int id = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
        if(id >= n) return;

        int index = id;
        int j = id % in_w;
        id /= in_w;
        int i = id % in_h;
        id /= in_h;
        int k = id % in_c;
        id /= in_c;
        int b = id;

        int w_offset = -pad/2;
        int h_offset = -pad/2;

        float d = 0;
        int l, m;
        for(l = -area; l < area+1; ++l){
            for(m = -area; m < area+1; ++m){
                int out_w = (j-w_offset)/stride + m;
                int out_h = (i-h_offset)/stride + l;
                int out_index = out_w + w*(out_h + h*(k + c*b));
                int valid = (out_w >= 0 && out_w < w &&
                        out_h >= 0 && out_h < h);
                d += (valid && indexes[out_index] == index) ? delta[out_index] : 0;
            }
        }
        prev_delta[index] += d;
    }


    void forward_maxpool_gpu(int n,int w,int h,int c,int stride, 
        int size, int pad, float *in,float *out, int *indexes)
    {
        forward_maxpool_kernel<<<cuda_gridsize(n), BLOCK>>>(n, h, w, c, stride, 
            size, pad, in, out, indexes);
        cuda_check_error(cudaPeekAtLastError());
    } 

    void backward_maxpool_gpu(int n,int w,int h,int c,int stride, 
        int size, int pad, float *in_diff,float *out_diff, int *indexes)
    {
        backward_maxpool_kernel<<<cuda_gridsize(n), BLOCK>>>(n, h, w, c, stride,
            size, pad, in_diff, out_diff, indexes);
        check_error(cudaPeekAtLastError());
    }

    
    __global__ void forward_avgpool_kernel(int n, int w, int h, int c, float *input, float *output)
    {
        int id = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
        if(id >= n) return;

        int k = id % c;
        id /= c;
        int b = id;

        int i;
        int out_index = (k + c*b);
        output[out_index] = 0;
        for(i = 0; i < w*h; ++i){
            int in_index = i + h*w*(k + b*c);
            output[out_index] += input[in_index];
        }
        output[out_index] /= w*h;
    }

    __global__ void backward_avgpool_kernel(int n, int w, int h, int c, float *in_delta, float *out_delta)
    {
        int id = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
        if(id >= n) return;

        int k = id % c;
        id /= c;
        int b = id;

        int i;
        int out_index = (k + c*b);
        for(i = 0; i < w*h; ++i){
            int in_index = i + h*w*(k + b*c);
            in_delta[in_index] += out_delta[out_index] / (w*h);
        }
    }


    void forward_meanpool_gpu(int n, int w, int h, int c, float *in, float *out)
    {
        forward_avgpool_kernel<<<cuda_gridsize(n), BLOCK>>>(
            n, w, h, c, in, out);
        cuda_check_error(cudaPeekAtLastError());
    } 

    void backward_meanpool_gpu(int n, int w, int h, int c, float *in_diff, float *out_diff)
    {
        backward_avgpool_kernel<<<cuda_gridsize(n), BLOCK>>>(
            n, w, h, c, in_diff, out_diff);
        check_error(cudaPeekAtLastError());
    }

}