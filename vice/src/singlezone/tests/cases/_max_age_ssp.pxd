# cython: language_level = 3, boundscheck = False 

from __future__ import absolute_import 
from .....core.singlezone._singlezone cimport c_singlezone 
from .....core.objects._singlezone cimport SINGLEZONE 

### For use in constructing the max age SSP edge-case test ### 
cdef class max_age_ssp(c_singlezone): 
	pass 

cdef extern from "../../singlezone.h": 
	unsigned short singlezone_setup(SINGLEZONE *sz) 
	void singlezone_evolve_no_setup_no_clean(SINGLEZONE *sz) 

cdef extern from "../../mdf.h": 
	void normalize_MDF(SINGLEZONE *sz) 

cdef extern from "../../../io/singlezone.h": 
	void write_mdf_output(SINGLEZONE sz) 




### Max Age SSP unit tests ### 
cdef extern from "../agb.h": 
	unsigned short max_age_ssp_test_m_AGB(SINGLEZONE *sz) 

cdef extern from "../ccsne.h": 
	unsigned short max_age_ssp_test_m_ccsne(SINGLEZONE *sz) 

cdef extern from "../element.h": 
	unsigned short max_age_ssp_test_update_element_mass(SINGLEZONE *sz) 
	unsigned short max_age_ssp_test_onH(SINGLEZONE *sz) 

cdef extern from "../ism.h": 
	unsigned short max_age_ssp_test_update_gas_evolution(SINGLEZONE *sz) 
	unsigned short max_age_ssp_test_get_outflow_rate(SINGLEZONE *sz) 
	unsigned short max_age_ssp_test_singlezone_unretained(SINGLEZONE *sz) 

cdef extern from "../mdf.h": 
	unsigned short max_age_ssp_test_MDF(SINGLEZONE *sz) 

cdef extern from "../recycling.h": 
	unsigned short max_age_ssp_test_mass_recycled(SINGLEZONE *sz) 

cdef extern from "../singlezone.h": 
	unsigned short max_age_ssp_test_singlezone_stellar_mass(SINGLEZONE *sz) 

cdef extern from "../sneia.h": 
	unsigned short max_age_ssp_test_mdot_sneia(SINGLEZONE *sz) 
