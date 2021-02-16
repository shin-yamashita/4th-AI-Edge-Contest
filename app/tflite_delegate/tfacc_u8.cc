/*
 * cma_alloc.cc
 *
 *  Created on: Oct 28, 2020
 *      Author: shin
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <signal.h>

#include "tfacc_u8.h"

static uint32_t* m_reg = NULL;	// sr_cpu memory area
static volatile uint32_t *accparams = NULL;

static uint8_t* tfacc_buf = NULL;	// cma arena area
static uint8_t* last = NULL;
static uint32_t cma_phy_base;
static size_t n_alloc = 0;

static uint8_t* output_buff = NULL;
static uint8_t* input_buff = NULL;
static uint8_t* filter_buff = NULL;
static uint32_t* bias_buff = NULL;
static size_t output_buff_size;
static size_t input_buff_size;
static size_t filter_buff_size;
static size_t bias_buff_size;   //(bytes)

#define CMA_MAX 0x6000000

#ifndef ULTRA96
uint32_t cma_get_phy_addr(void *pt)
{
    return (uint8_t*)pt - tfacc_buf;
}
void cma_flush_cache(void *buf, unsigned int phys_addr, int size)
{
//    fprintf(stderr, "cma_flush: %p %x %d\n", buf, phys_addr, size);
}
void cma_invalidate_cache(void *buf, unsigned int phys_addr, int size)
{
//    fprintf(stderr, "cma_clean: %p %x %d\n", buf, phys_addr, size);
}
#endif
void PL_if_free()
{
#ifdef ULTRA96
    if(m_reg){
        cma_munmap(m_reg, 0x10000);
        fprintf(stderr, "PL_if_free():cma_munmap\n");
        m_reg = NULL;
    }
    if(tfacc_buf){
        cma_free(tfacc_buf);
        fprintf(stderr, "PL_if_free():cma_free\n");
        tfacc_buf = NULL;
    }
#endif
}
void abort_handle(int sig)
{
    PL_if_free();
}
void PL_if_config()
{
#ifdef ULTRA96
    signal(SIGKILL, abort_handle);
    signal(SIGINT, abort_handle);
    if(!m_reg){
        m_reg = reinterpret_cast<uint32_t*>(cma_mmap(0xa0000000, 0x10000));
        if(!m_reg){
            perror("cma_mmap()\n");
        }
        accparams = reinterpret_cast<uint32_t*>(&m_reg[0x100/4]);
        fprintf(stderr, "PL_if_config(): m_reg:%p accparam:%p\n", m_reg, accparams);
        atexit(PL_if_free);
    }
    if(!tfacc_buf){
        tfacc_buf = reinterpret_cast<uint8_t*>(cma_alloc(CMA_MAX, 1));   // 64MB cachable
        cma_phy_base = cma_get_phy_addr(tfacc_buf);
        if(!tfacc_buf){
            perror("cma_alloc()\n");
        }
        fprintf(stderr, "PL_if_config(): tfacc_buf:%p\n", tfacc_buf);
    }
#else
    m_reg = (uint32_t*)malloc(0x10000);
    accparams = &m_reg[0x100/4];
    tfacc_buf = (uint8_t*)malloc(CMA_MAX);
    cma_phy_base = 0;
#endif
    output_buff_size = 0;
    input_buff_size = 0;
    filter_buff_size = 0;
    bias_buff_size = 0;
}

void cma_malloc_init()
{
    PL_if_config();
    last = tfacc_buf;
    n_alloc = 0;
    output_buff = NULL;
}
void *cma_malloc(size_t bytes)  // 16 bytes align
{
    uint8_t *newpt = last;
    bytes = (bytes + 0x1ff) & ~0x1ff;
    n_alloc += bytes;
    last += bytes;
    if(n_alloc >= CMA_MAX){
        fprintf(stderr,"cma_malloc() : memory over  %ld\n", n_alloc);
        exit(-1);
    }
 //   fprintf(stderr,"cma_malloc(%zd) : %p\n", bytes, newpt);
    return newpt;
}

void prepare_buffer_size(TfaccMemory m, size_t bytes)
{
    switch(m){
    case kTfaccOutput:  output_buff_size = output_buff_size < bytes ? bytes : output_buff_size;
        break;
    case kTfaccInput:   input_buff_size = input_buff_size < bytes ? bytes : input_buff_size;
        break;
    case kTfaccFilter:  filter_buff_size = filter_buff_size < bytes ? bytes : filter_buff_size;
        break;
    case kTfaccBias:    bias_buff_size = bias_buff_size < bytes ? bytes : bias_buff_size;
        break;
    }
}

void cma_malloc_buffers()
{
    if(output_buff == NULL){
        output_buff = (uint8_t*)cma_malloc(output_buff_size);
        input_buff =  (uint8_t*)cma_malloc(input_buff_size);
        filter_buff = (uint8_t*)cma_malloc(filter_buff_size);
        bias_buff =   (uint32_t*)cma_malloc(bias_buff_size);
 //       fprintf(stderr, "cma_malloc_buffers(): o %ld  i %ld  f %ld  b %ld  n_alloc: %ld\n",
 //               output_buff_size, input_buff_size, filter_buff_size, bias_buff_size, n_alloc);
    }
}

size_t get_cma_malloc_size()
{
    return n_alloc;
}

int in_cma(void *pt)
{
    uint32_t ppt = cma_get_phy_addr(pt);
    return ppt >= cma_phy_base && ppt <= (last-tfacc_buf)+cma_phy_base;
}

void set_param(int n, uint32_t param){
    if(accparams) accparams[n] = param;
}
uint32_t get_param(int n){
    if(accparams) return accparams[n];
    return -1;
}

void set_data(TfaccMemory m, void *pt, int nbyte)   // 0/1/2/3  out/in/filt/bias
{
    switch(m){
    case kTfaccOutput:
        if(!in_cma(pt)){
            cma_invalidate_cache(output_buff, cma_get_phy_addr(output_buff), nbyte);
            set_param(0, cma_get_phy_addr(output_buff));
        }else{
            cma_invalidate_cache(pt, cma_get_phy_addr(pt), nbyte);
            set_param(0, cma_get_phy_addr(pt));
        }
        break;
    case kTfaccInput:
        if(!in_cma(pt)){
            memcpy(input_buff,  pt,  nbyte);
            cma_flush_cache(input_buff, cma_get_phy_addr(input_buff) , nbyte);
            set_param(1, cma_get_phy_addr(input_buff));
        }else{
            cma_flush_cache(pt, cma_get_phy_addr(pt) , nbyte);
            set_param(1, cma_get_phy_addr(pt));
        }
        break;
    case kTfaccFilter:
        memcpy(filter_buff,  pt,  nbyte);
        cma_flush_cache(filter_buff, cma_get_phy_addr(filter_buff) , nbyte);
        set_param(2, cma_get_phy_addr(filter_buff));
        break;
    case kTfaccBias:
        memcpy(bias_buff,  pt,  nbyte);
        cma_flush_cache(bias_buff, cma_get_phy_addr(bias_buff) , nbyte);
        set_param(3, cma_get_phy_addr(bias_buff));
        break;
    }
}

void get_outdata(uint8_t *pt, int nbyte)
{
    if(!in_cma(pt)){
        cma_flush_cache(output_buff, cma_get_phy_addr(output_buff) , nbyte);
        memcpy(pt, output_buff, nbyte);
    }else{
        cma_flush_cache(pt, cma_get_phy_addr(pt) , nbyte);
    }
}

