#ifndef __javernn_sequence_h__
#define __javernn_sequence_h__

#include "javernn/ops.h"

namespace javernn{
    class Sequence:public Ops{
    public:
        void Backward(const std::vector<Tensor> &cost);
        std::vector<Tensor> Forward(const std::vector<Tensor> &inputs);  
        void UpdateWeights(Optimizer &opt);
        void Setup();
        void Add(Op* op);
        void Construct();
    private:
        std::vector<Op *> ops_;
    };
}

#endif