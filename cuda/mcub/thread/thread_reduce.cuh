/******************************************************************************
 * Copyright (c) 2011, Duane Merrill.  All rights reserved.
 * Copyright (c) 2011-2016, NVIDIA CORPORATION.  All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/**
 * \file
 * Thread utilities for sequential reduction over statically-sized array types
 */

 /*
  * ###########################################################################
  * Copyright (c) 2016, Los Alamos National Security, LLC All rights
  * reserved. Copyright 2016. Los Alamos National Security, LLC. This
  * software was produced under U.S. Government contract DE-AC52-06NA25396
  * for Los Alamos National Laboratory (LANL), which is operated by Los
  * Alamos National Security, LLC for the U.S. Department of Energy. The
  * U.S. Government has rights to use, reproduce, and distribute this
  * software.  NEITHER THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY,
  * LLC MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY
  * FOR THE USE OF THIS SOFTWARE.  If software is modified to produce
  * derivative works, such modified software should be clearly marked, so
  * as not to confuse it with the version available from LANL.
  *  
  * Additionally, redistribution and use in source and binary forms, with
  * or without modification, are permitted provided that the following
  * conditions are met: 1.       Redistributions of source code must
  * retain the above copyright notice, this list of conditions and the
  * following disclaimer. 2.      Redistributions in binary form must
  * reproduce the above copyright notice, this list of conditions and the
  * following disclaimer in the documentation and/or other materials
  * provided with the distribution. 3.      Neither the name of Los Alamos
  * National Security, LLC, Los Alamos National Laboratory, LANL, the U.S.
  * Government, nor the names of its contributors may be used to endorse
  * or promote products derived from this software without specific prior
  * written permission.
   
  * THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC AND
  * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
  * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
  * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL LOS
  * ALAMOS NATIONAL SECURITY, LLC OR CONTRIBUTORS BE LIABLE FOR ANY
  * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  * OTHERWISE) ARISING IN ANY WAY OUT OF THE US
  * ########################################################################### 
  * 
  * Notes
  *
  * ##### 
  */

#pragma once

#include "../thread/thread_operators.cuh"
#include "../util_namespace.cuh"

/// Optional outer namespace(s)
CUB_NS_PREFIX

/// CUB namespace
namespace cub {

/**
 * \addtogroup UtilModule
 * @{
 */

/**
 * \name Sequential reduction over statically-sized array types
 * @{
 */


// ndm
template <
    int         LENGTH,
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T*                  input,                  ///< [in] Input array
    ReductionOp         reduction_op,           ///< [in] Binary reduction operator
    T                   prefix,                 ///< [in] Prefix to seed reduction with
    Int2Type<LENGTH>    length,
    int                 index,
    void(*bodyFunc)(int, void*, void*),
    void*               args)
{
    // ndm

    T addend;
    bodyFunc(index, args, &addend);

    prefix = reduction_op(prefix, addend);

    return ThreadReduce(input + 1, reduction_op, prefix, Int2Type<LENGTH - 1>(), index + 1, bodyFunc, args);
}

template <
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T*                  input,                  ///< [in] Input array
    ReductionOp         reduction_op,           ///< [in] Binary reduction operator
    T                   prefix,                 ///< [in] Prefix to seed reduction with
    Int2Type<0>         length,
    int                 index,
    void(*bodyFunc)(int, void*, void*),
    void*               args)
{
    return prefix;
}


/**
 * \brief Perform a sequential reduction over \p LENGTH elements of the \p input array, seeded with the specified \p prefix.  The aggregate is returned.
 *
 * \tparam LENGTH     LengthT of input array
 * \tparam T          <b>[inferred]</b> The data type to be reduced.
 * \tparam ScanOp     <b>[inferred]</b> Binary reduction operator type having member <tt>T operator()(const T &a, const T &b)</tt>
 */
template <
    int         LENGTH,
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T*          input,                  ///< [in] Input array
    ReductionOp reduction_op,           ///< [in] Binary reduction operator
    T           prefix,
    void(*bodyFunc)(int, void*, void*),
    void* args)                 ///< [in] Prefix to seed reduction with
{
    return ThreadReduce(input, reduction_op, prefix, Int2Type<LENGTH>(), 0, bodyFunc, args);
}


/**
 * \brief Perform a sequential reduction over \p LENGTH elements of the \p input array.  The aggregate is returned.
 *
 * \tparam LENGTH     LengthT of input array
 * \tparam T          <b>[inferred]</b> The data type to be reduced.
 * \tparam ScanOp     <b>[inferred]</b> Binary reduction operator type having member <tt>T operator()(const T &a, const T &b)</tt>
 */

// ndm
template <
    int         LENGTH,
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T*          input,                  ///< [in] Input array
    ReductionOp reduction_op,
    void(*bodyFunc)(int, void*, void*),
    void* args)
               ///< [in] Binary reduction operator
{
    // ndm

    T prefix;
    (*bodyFunc)(0, args, &prefix);

    return ThreadReduce<LENGTH - 1>(input + 1, reduction_op, prefix, bodyFunc, args);
}

// ndm

/**
 * \brief Perform a sequential reduction over the statically-sized \p input array, seeded with the specified \p prefix.  The aggregate is returned.
 *
 * \tparam LENGTH     <b>[inferred]</b> LengthT of \p input array
 * \tparam T          <b>[inferred]</b> The data type to be reduced.
 * \tparam ScanOp     <b>[inferred]</b> Binary reduction operator type having member <tt>T operator()(const T &a, const T &b)</tt>
 */
template <
    int         LENGTH,
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T           (&input)[LENGTH],       ///< [in] Input array
    ReductionOp reduction_op,           ///< [in] Binary reduction operator
    T           prefix,
    void(*bodyFunc)(int, void*, void*),
    void*               args)                 ///< [in] Prefix to seed reduction with
{
    // ndm - pass 0 for index?
    return ThreadReduce(input, reduction_op, prefix, Int2Type<LENGTH>(), 0, bodyFunc, args);
}

// ndm

/**
 * \brief Serial reduction with the specified operator
 *
 * \tparam LENGTH     <b>[inferred]</b> LengthT of \p input array
 * \tparam T          <b>[inferred]</b> The data type to be reduced.
 * \tparam ScanOp     <b>[inferred]</b> Binary reduction operator type having member <tt>T operator()(const T &a, const T &b)</tt>
 */
template <
    int         LENGTH,
    typename    T,
    typename    ReductionOp>
__device__ __forceinline__ T ThreadReduce(
    T           (&input)[LENGTH],       ///< [in] Input array
    ReductionOp reduction_op,
    void(*bodyFunc)(int, void*, void*),
    void* args)           ///< [in] Binary reduction operator
{
    return ThreadReduce<LENGTH>((T*) input, reduction_op, bodyFunc, args);
}


//@}  end member group

/** @} */       // end group UtilModule

}               // CUB namespace
CUB_NS_POSTFIX  // Optional outer namespace(s)
