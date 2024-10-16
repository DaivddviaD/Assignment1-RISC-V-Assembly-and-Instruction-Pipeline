# include <stdlib.h>
# include <stdio.h>
# include <stdint.h>

typedef struct {
    uint16_t bits;
} bf16_t;
static inline bf16_t fp32_to_bf16(float s)
{
    bf16_t h;
    union {
        float f;
        uint32_t i;
    } u = {.f = s};
    if ((u.i & 0x7fffffff) > 0x7f800000) { /* NaN */
        h.bits = (u.i >> 16) | 64;         /* force to quiet */
        return h;                                                                                                                                             
    }
    h.bits = (u.i + (0x7fff + ((u.i >> 0x10) & 1))) >> 0x10;
    return h;
}
static inline float bf16_to_fp32(bf16_t h)
{
    union {
        float f;
        uint32_t i;
    } u = {.i = (uint32_t)h.bits << 16};
    return u.f;
}

int main (){
    float s = 101189.5;
    union {
        float f;
        uint32_t i;
    } u = {.f = s};
    

    printf("The float 32 format is: ");
    for (int ii = 0; ii < 32; ii ++){
        printf("%d", (u.i >> (31-ii)) & 1);
    }
    printf("\n");

    bf16_t h = fp32_to_bf16 (s);
    printf("The float 16 format is: ");
    for (int i = 0; i < 16; i ++){
        printf("%d", h.bits >> (15-i) & 1);
    }
    printf("\n");

    return 0;
}
