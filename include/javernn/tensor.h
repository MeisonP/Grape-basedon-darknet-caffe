#ifndef __JAVERNN_TENSOR_H__
#define __JAVERNN_TENSOR_H__

#include <vector>
#include <memory>
#include "javernn/synced_memory.h"
#include "javernn/shape.h"

namespace javernn{
    enum  TENSOR_TYPE{
        DATA,
        WEIGHTS,
        BIAS,
        LABEL,
        AUX,
    };
    class Op;
    class Tensor {
    public:
        Tensor(Op *prev,Shape shape,TENSOR_TYPE type,CAL_MODE mode)
        : prev_(prev),shape_(shape),type_(type),mode_(mode){
            data_ = std::make_shared<SyncedMemory>(shape_.count(),mode_);
            diff_ = std::make_shared<SyncedMemory>(shape_.count(),mode_);
        }
        virtual ~Tensor() {};

        inline const std::vector<Op *> &next() const { return next_; }
        inline Op *prev() { return prev_; }
        inline const Op *prev() const { return prev_; }
        inline void add_next_op(Op *next) { next_.push_back(next); }
        const Shape &shape() const { return shape_; }
        TENSOR_TYPE vtype() const { return type_; }
    private:
        std::shared_ptr<SyncedMemory> data_;
        std::shared_ptr<SyncedMemory> diff_;
        Op *prev_;                // previous node, "producer" of this tensor
        Shape shape_;
        TENSOR_TYPE type_;
        CAL_MODE mode_;
        std::vector<Op *> next_;  // next nodes, "consumers" of this tensor
    };
}

#endif