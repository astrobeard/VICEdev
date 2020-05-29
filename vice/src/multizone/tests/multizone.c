/* 
 * This file implements testing of the multizone routines in the parent 
 * directory. 
 */ 

#include <stdlib.h> 
#include "../multizone.h" 
#include "../../utils.h" 
#include "../../singlezone/singlezone.h" 


/* 
 * Performs the no migration edge-case test on the multizone_stellar_mass 
 * function in the parent directory. 
 * 
 * Parameters 
 * ==========
 * mz: 		A pointer to the multizone object to run the test on 
 * 
 * Returns 
 * =======
 * 1 on success, 0 on failure 
 * 
 * header: multizone.h 
 */ 
extern unsigned short no_migration_test_multizone_stellar_mass(MULTIZONE *mz) {

	unsigned int i; 
	double *actual = multizone_stellar_mass(*mz); 
	if (actual != NULL) {

		/* 
		 * Time integrate the star formation history in each zone, then make 
		 * sure it is within round-off error of what is reported by the 
		 * multizone_stellar_mass function. This is expected for no-migration 
		 * scenarios. 
		 */ 
		double *expected = (double *) malloc ((*(*mz).mig).n_zones * 
			sizeof(double)); 
		for (i = 0u; i < (*(*mz).mig).n_zones; i++) { 
			/* 
			 * The multizone_stellar_mass function counts the current timestep 
			 * while the singlezone_stellar_mass function does. This difference 
			 * is due simply to when the inject_tracers function is called. 
			 */ 
			expected[i] = singlezone_stellar_mass(*(*mz).zones[i]) + (
				(*(*(*mz).zones[i]).ism).star_formation_rate * 
				(*(*mz).zones[i]).dt * 
				(1 - (*(*(*mz).zones[i]).ssp).crf[1]) 
			); 
		} 

		unsigned short status = 1u; 
		for (i = 0u; i < (*(*mz).mig).n_zones; i++) {
			double percent_difference = absval(
				(actual[i] - expected[i]) / expected[i] 
			); 
			/* This test usually has an accuracy of ~.001 */ 
			status &= percent_difference < 2e-3; 
			if (!status) break; 
		} 
		free(actual); 
		free(expected); 
		return status; 

	} else {
		return 0u; 
	}

}

