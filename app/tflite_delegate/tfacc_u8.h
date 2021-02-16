/*
 * tfacc_u8.h
 *
 *  Created on: Oct 28, 2020
 *      Author: shin
 */

#ifndef TFACC_U8_H_
#define TFACC_U8_H_

#ifdef ULTRA96
extern "C" {
#include <libxlnk_cma.h>
}
#else
uint32_t cma_get_phy_addr(void *pt);
#endif

typedef enum {
    kTfaccNstage = 4,
    kTfaccDWen,
    kTfaccRun,
} TfaccCtrl;

typedef enum {
    kTfaccOutput = 0,
    kTfaccInput,
    kTfaccFilter,
    kTfaccBias,
} TfaccMemory;

void cma_malloc_init();
void *cma_malloc(size_t bytes);
void prepare_buffer_size(TfaccMemory m, size_t bytes);
void cma_malloc_buffers();

size_t get_cma_malloc_size();
int  in_cma(void *pt);

// tfacc parameters
void set_param(int n, uint32_t param);
uint32_t get_param(int n);
#define set_accparam(n, p)  set_param(7+(n), (p))

void set_data(TfaccMemory m, void *pt, int nbyte);
void get_outdata(uint8_t *pt, int nbyte);

#endif // TFACC_U8_H_
