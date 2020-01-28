
from __future__ import absolute_import 
try: 
	__VICE_SETUP__ 
except NameError: 
	__VICE_SETUP__ = False 

if not __VICE_SETUP__: 
	__all__ = [
		"singlechain"
	] 
	from .singlechain import singlechain  
else: 
	pass 
