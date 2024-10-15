# include <stdlib.h>
# include <stdio.h>
# include <stdint.h>
# define iteration 5

static void showbits(uint32_t x){
    for (int i = 0; i < 32; i ++)
    printf("%d", (x >> (31 - i)) & 1);

    printf("\n");
}

uint8_t CLZ (uint32_t x){
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    

    x -= ((x >> 1) & 0x55555555);
    x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);


    return (32 - (x & 0xff));
}

static inline uint32_t float2int(float alpha){
    union {
        uint32_t bits;
        float value;
    }fp32 = {.value = alpha};

    uint32_t sign = fp32.bits & 0x80000000 >> 31;
    uint32_t exp = (fp32.bits >> 23) & 0b11111111;
    uint32_t metissa = (fp32.bits & 0x7FFFFF) + 0x800000;

    uint32_t round_a = exp > 127 ? metissa << exp -127 : metissa >> 127 - exp;
    round_a = (round_a + 0x400000)>> 23;
    return round_a;
}

static inline float int2float(uint32_t alpha){
    if (alpha){
        uint32_t exp = 32 - CLZ(alpha) - 1;
        uint32_t mantissa = (alpha << (23 - exp)) - 0x800000;
        union {
            uint32_t bits;
            float value;
        }fp32 = {.bits = ((exp + 127) << 23) | mantissa};
            return fp32.value;
    }else
        return alpha;
}

// a >= b
static inline float add_float(float a, float b){

    // 1. Handle special cases like NaN, infinity, zero.
    if (a == 0.0f) return b;
    if (b == 0.0f) return a;

    union {
        uint32_t bits;
        float value;
    } fpa = {.value = a}, fpb = {.value = b};

    uint32_t sign_a = fpa.bits & 0x80000000;
    uint32_t sign_b = fpb.bits & 0x80000000;

    // Extract absolute values
    uint32_t abs_a = fpa.bits & 0x7fffffff;
    uint32_t abs_b = fpb.bits & 0x7fffffff;

    // Ensure abs_a > abs_b
    if (abs_a < abs_b) {
        uint32_t temp = abs_a;
        abs_a = abs_b;
        abs_b = temp;
        temp = sign_a;
        sign_a = sign_b;
        sign_b = sign_a;
    }

    // Extract exponents and mantissas
    uint32_t exp_a = (abs_a >> 23) & 0xff;
    uint32_t exp_b = (abs_b >> 23) & 0xff;
    uint32_t mantissa_a;
    uint32_t mantissa_b;
    if (exp_a > 0){
        mantissa_a = (abs_a & 0x7fffff) | 0x800000; // Add implicit 1
    }
    else
        mantissa_a = (abs_a & 0x7fffff);
    
    if (exp_b > 0){
        mantissa_b = (abs_b & 0x7fffff) | 0x800000; // Add implicit 1
    }
    else{
        mantissa_b = (abs_b & 0x7fffff);
    }

    // Align mantissa_b with mantissa_a
    uint32_t diff_exp = exp_a - exp_b;
    mantissa_b >>= diff_exp;

    // Calculate resulting mantissa based on sign difference
    uint32_t mantissa;
    if ((sign_a >> 31) ^ (sign_b >> 31)) {
        mantissa = mantissa_a - mantissa_b;
    } else {
        mantissa = mantissa_a + mantissa_b;
    }

    // Normalize mantissa if necessary
    uint32_t exp = exp_a;
    if (mantissa & 0x1000000) {
        mantissa >>= 1;
        exp++;
    } else {
        while (mantissa && !(mantissa & 0x800000)) {
            mantissa <<= 1;
            exp--;
        }
    }

    // Handle underflow and overflow
    if (exp <= 0) return 0.0f;

    union {
        uint32_t bits;
        float value;
    } out = {.bits = sign_a | (exp << 23) | (mantissa & 0x7fffff)};

    return out.value;
}


    // seperate float32's different conpoment
    //  ________________________________________________________________
    // |_0_|_______8______|____________________23_______________________|
    //  sign  exponential                   mantissa

static inline float div_float(float p, float q){

    union {
        uint32_t bits;
        float value;
    } fpp = {.value = p};

    // Extract sign, exponent, and mantissa of p
    uint32_t sign_p = (fpp.bits >> 31);
    uint32_t exp_p = (fpp.bits >> 23) & 0xff;
    uint32_t mantissa_p;

    // Normalize mantissa of p
    if (exp_p > 0) {
        mantissa_p = (fpp.bits & 0x7FFFFF) | 0x800000; // Add implicit 1
    } else {
        mantissa_p = (fpp.bits & 0x7FFFFF);
        int dif = CLZ(mantissa_p) - 8;
        mantissa_p <<= dif;
        exp_p = 1 -dif;
    }




    union {
        uint32_t bits;
        float value;
    } fpq = {.value = q};

    // Extract sign, exponent, and mantissa of q
    uint32_t sign_q = (fpq.bits >> 31) & 0x1;
    uint32_t exp_q = (fpq.bits >> 23) & 0xff;
    uint32_t mantissa_q;
    
    // Normalize mantissa of 
    if (exp_q > 0) {
        mantissa_q = (fpq.bits & 0x7FFFFF) | 0x800000; // Add implicit 1
    } else {
        mantissa_q = (fpq.bits & 0x7FFFFF);
        int dif = CLZ(mantissa_q) - 8;
        mantissa_q <<= dif;
        exp_q = 1 -dif;
    }

    // Compute sign, exponent, and mantissa of the result
    uint32_t sign = sign_p ^ sign_q;
    int exp = exp_p - exp_q + 127;
    uint32_t mantissa = 0;

    // Align mantissa_p to be larger than mantissa_q
    if (mantissa_p < mantissa_q) {
        mantissa_p <<= 1;
        exp--;
    }


    // Perform division of mantissas using bitwise long division
    int nbits = 25;
    if (exp < 0) {
        nbits += exp;
        exp = 0;
        if (nbits < 0) {
            return 0;
        }
    }

    for (int i = 0; i < nbits; i++) {
        mantissa <<= 1;
        if (mantissa_p >= mantissa_q) {
            mantissa_p -= mantissa_q;
            mantissa |= 1;
        }
        mantissa_p <<= 1;
    }
  
    // Round the result
    uint8_t odd, rnd, sticky;
    sticky = (mantissa_p != 0);
    rnd = (mantissa & 1);
    odd = (mantissa & 2);
    mantissa = (mantissa >> 1) + (rnd & (sticky | odd));

    // Normalize the result if needed
    int lz = CLZ(mantissa);
    if (exp == 0 && (lz < 9)) {
        mantissa >>= (9 - lz);
        exp += (9 - lz);
    }

    // Combine the sign, exponent, and mantissa to form the final result
    union {
        uint32_t bits;
        float value;
    } output = {.bits = (sign << 31) | (exp << 23) | (mantissa & 0x7FFFFF)};

    return output.value;
}




static inline float Newtons_method(uint32_t alpha){
    

    // do the leading zero counting
    int lzc = (32 - CLZ(alpha))/2;
    lzc = alpha >> lzc;
    //init float
    float output = int2float(lzc);

    if (output == 0){
        output = 2;
    }
    
    float input = int2float(alpha);

    //iteration loop
    for (int i = 0; i < iteration; i++){
        float temp = div_float(input, output);
        output = add_float(output , temp); 
        output = div_float(output, (float) 2);
    }
    union {
        uint32_t bits;
        float value;
    } O = {.value = output};
    showbits(O.bits);
    return output;
}


int main(){
    uint32_t alpha = 1160030; // The original number
    float root = Newtons_method(alpha);
    printf("%d roots = %f\n",alpha, root);


    return 0;

}