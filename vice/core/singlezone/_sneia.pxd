# cython: language_level = 3, boundscheck = False 

from __future__ import absolute_import 
from ._element cimport ELEMENT 

cdef extern from "../../src/objects.h": 
	ctypedef struct SNEIA_YIELD_SPECS: 
		char *dtd 
		double *yield_ 
		double *grid 
		double *RIa 
		double tau_ia 
		double t_d 
		double entrainment 

cdef extern from "../../src/sneia.h": 
	cdef double PLAW_DTD_INDEX 
	cdef double RIA_MAX_EVAL_TIME 
	cdef double IA_YIELD_STEP 
	cdef double IA_YIELD_GRID_MIN 
	cdef double IA_YIELD_GRID_MAX 
	SNEIA_YIELD_SPECS *sneia_yield_initialize() 
	void sneia_yield_free(SNEIA_YIELD_SPECS *sneia_yield) 
	void normalize_RIa(ELEMENT *e, unsigned long length) 
