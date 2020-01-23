# cython: language_level = 3, boundscheck = False

cdef extern from "../../src/objects.h": 
	ctypedef struct AGB_YIELD_GRID: 
		double **grid
		double *m
		double *z
		unsigned long n_m
		unsigned long n_z 
		double entrainment 

cdef extern from "../../src/agb.h": 
	AGB_YIELD_GRID *agb_yield_grid_initialize() 
	void agb_yield_grid_free(AGB_YIELD_GRID *agb_grid) 
	double AGB_Z_GRID_STEPSIZE 
	double AGB_Z_GRID_MIN 
	double AGB_Z_GRID_MAX 	
