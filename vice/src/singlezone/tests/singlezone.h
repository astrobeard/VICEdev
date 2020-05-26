
#ifndef SINGLEZONE_TESTS_SINGLEZONE_H 
#define SINGLEZONE_TESTS_SINGLEZONE_H 

#ifdef __cplusplus 
extern "C" { 
#endif /* __cplusplus */ 

/* 
 * Performs the quiescence edge-case test on the singlezone_stellar_mass 
 * function in the parent directory. 
 * 
 * Parameters 
 * ==========
 * sz: 		A pointer to the singlezone object to run the test on 
 * 
 * Returns 
 * =======
 * 1 on success, 0 on failure 
 * 
 * source: singlezone.c 
 */ 
extern unsigned short quiescence_test_singlezone_stellar_mass(SINGLEZONE *sz); 

#ifdef __cplusplus 
} 
#endif /* __cplusplus */ 

#endif /* SINGLEZONE_TESTS_SINGLEZONE_H */ 
