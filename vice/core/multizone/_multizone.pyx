# cython: language_level = 3, boundscheck = False 

# Python imports 
from __future__ import absolute_import 
from ..._globals import _VERSION_ERROR_ 
from ..._globals import ScienceWarning 
from ..dataframe._builtin_dataframes import atomic_number 
from ..dataframe._builtin_dataframes import solar_z 
from ..dataframe._builtin_dataframes import sources 
from ..outputs import output 
from ...yields import agb 
from ...yields import ccsne 
from ...yields import sneia 
from ..pickles import jar 
from .. import _pyutils 
import warnings 
import numbers 
import sys 
import os 
if sys.version_info[:2] == (2, 7): 
	strcomp = basestring 
	input = raw_input 
elif sys.version_info[:2] >= (3, 5): 
	strcomp = str 
else: 
	_VERSION_ERROR_() 
from libc.stdlib cimport malloc 
from libc.string cimport strlen 
from .._cutils cimport set_string 
from .._cutils cimport copy_pylist 
from ..objects cimport _singlezone 
from . cimport _tracer 
from . cimport _zone_array 
from . cimport _multizone 
from . cimport _migration 

""" 
NOTES 
===== 
cdef class objects do not transfer the docstrings of class attributes to the 
compiled output, leaving out the internal documentation. For this reason, 
wrapping of the multizone object has two layers -> a python class and a 
C class. In the python class, there is only one attribute: the C version of 
the wrapper. The docstrings are written here, and each function/setter 
only calls the C version of the wrapper. While this is a more complicated 
wrapper, it preserves the internal documentation. In order to maximize 
readability, the setter functions of the C version of the wrapper have brief 
notes on the physical interpretation of each attribute as well as the allowed 
types and values. 

While the user sees the number of star particles formed per zone per timestep 
as 'n_stars', that value exists under the hood as 'n_tracers'. Star particles 
are referred to in VICE's C library as tracer particles rather than star 
particles. 
""" 

cdef class c_multizone: 

	""" 
	Wrapping of the C version of the multizone object. 
	""" 

	# cdef MULTIZONE *_mz 
	# cdef zone_array _zones 
	# cdef migration_specifications _migration 

	def __cinit__(self, 
		n_zones = 10, 
		name = "multizonemodel", 
		n_stars = 1, 
		simple = False, 
		verbose = False): 

		assert isinstance(n_zones, int), "Internal Error" 
		assert n_zones > 0, "Internal Error" 
		self._mz = _multizone.multizone_initialize(n_zones) 
		self._zones = _zone_array.zone_array(n_zones) 
		for i in range(n_zones): 
			_multizone.link_zone(
				self._mz, 
				self._zones[i]._singlezone__zone_object_address(), 
				i) 


	def __init__(self, 
		n_zones = 10, 
		name = "multizonemodel", 
		n_stars = 1, 
		simple = False, 
		verbose = False): 

		assert isinstance(n_zones, int), "Internal Error" 
		assert n_zones > 0, "Internal Error" 
		self.name = name 
		self._migration = _migration.mig_specs(n_zones) 
		self.n_tracers = n_stars 
		self.simple = simple 
		self.verbose = verbose 

	def __dealloc__(self): 
		_multizone.multizone_free(self._mz) 


	@property 
	def zones(self): 
		# docstring in python version 
		return self._zones 

	@property 
	def name(self): 
		# docstring in python version 
		return "".join([chr(self._mz[0].name[i]) for i in range(
			strlen(self._mz[0].name))])[:-5] 

	@name.setter 
	def name(self, value): 
		""" 
		Name of the simulation, also the directory that the output is written 
		to. 

		Allowed Types 
		============= 
		str 

		Allows Values 
		============= 
		Simple strings, or those of the format 'path/to/dir' 

		All values will pass the setter except for empty strings. Those that 
		are not valid directory names will fail at runtime when self.run() is 
		called. 
		""" 
		if isinstance(value, strcomp): 
			if _pyutils.is_ascii(value): 
				if len(value) == 0: 
					raise ValueError("""Attribute 'name' must not be an \
empty string.""") 
				else: 
					pass 
				while value[-1] == '/': 
					# remove any '/' that the user puts on 
					value = value[:-1] 
				if value.lower().endswith(".vice"): 
					# force the .vice extension to lower-case 
					value = "%s.vice" % (value[:-5]) 
				else: 
					value = "%s.vice" % (value) 
				set_string(self._mz[0].name, value) 
			else: 
				raise ValueError("String must be ascii. Got: %s" % (value)) 
		else: 
			raise TypeError("Attribute 'name' must be of type str. Got: %s" % (
				type(value))) 

	@property 
	def n_zones(self): 
		# docstring in python version 
		return self._mz[0].mig[0].n_zones 

	@property 
	def n_tracers(self): 
		# docstring in python version 
		return self._mz[0].mig[0].n_tracers 

	@n_tracers.setter 
	def n_tracers(self, value): 
		""" 
		The number of tracer particles per zone per timestep 

		Allowed Types 
		============= 
		real number 

		Allowed Values 
		============== 
		Positive integers 
		""" 
		if isinstance(value, numbers.Number): 
			if value > 0: 
				if value % 1 == 0: 
					self._mz[0].mig[0].n_tracers = <unsigned int> value 
				else: 
					raise ValueError("""Attribute 'n_stars' must be \
interpretable as an integer. Got: %g""" % (value)) 
			else: 
				raise ValueError("""Attribute 'n_stars' must be positive. \
Got: %g""" % (value)) 
		else: 
			raise TypeError("""Attribute 'n_stars' must be an integer. \
Got: %s""" % (type(value))) 

	@property 
	def verbose(self): 
		# docstring in python version 
		return bool(self._mz[0].verbose) 

	@verbose.setter 
	def verbose(self, value): 
		""" 
		Whether or not to print the time as the simulation evolves. 

		Allowed Types 
		============= 
		bool 

		Allowed Values 
		============== 
		True and False 
		""" 
		if isinstance(value, numbers.Number) or isinstance(value, bool): 
			if value: 
				self._mz[0].verbose = 1 
			else: 
				self._mz[0].verbose = 0 
		else: 
			raise TypeError("""Attribute 'verbose' must be interpretable as \
a boolean. Got: %s""" % (type(value))) 

	@property 
	def simple(self): 
		# docstring in python version 
		return bool(self._mz[0].simple) 

	@simple.setter 
	def simple(self, value): 
		""" 
		Whether or not to forget about the migration histories of the tracer 
		particles. If this value is False, they're zone number at each 
		timestep will be taken into account 

		Allowed Types 
		============= 
		bool 

		Allowed Values 
		============== 
		True and False 
		""" 
		if isinstance(value, numbers.Number) or isinstance(value, bool): 
			if value: 
				warnings.warn("""\
Mixture models in which the positions of stars at intermediate times are not \
taken into account have been shown to oversimply age-abundance relations \
(Johnson et al. 2020, in prep). More accurate simulations arise when this \
attribute is False.""", ScienceWarning) 
				self._mz[0].simple = 1 
			else: 
				self._mz[0].simple = 0 
		else: 
			raise TypeError("""Attribute 'simple' must be interpretable as \
a boolean. Got: %s""" % (type(value))) 

	@property 
	def migration(self): 
		# docstring in python version 
		return self._migration 

	@migration.setter 
	def migration(self, value): 
		""" 
		The gas migration matrix. 

		Allowed Types 
		=============
		_migration.specs 

		Allowed Values 
		==============
		Any instance of the _migration.specs class 
		""" 
		if isinstance(value, _migration.mig_specs): 
			if value.gas.size == self.n_zones: 
				self._migration = value 
			else: 
				raise ValueError("""Migration specifications have incorrect \
number of zones. Got: %d. Required: %d.""" % (value.gas.size, self.n_zones)) 
		else: 
			raise TypeError("""Attribute 'migration' must be of type \
migration.specs. Got: %s""" % (type(value))) 


	def run(self, output_times, capture = False, overwrite = False): 
		""" 
		See docstring in python version of this class. 
		""" 
		self.align_name_attributes() 
		self.prep(output_times) 
		cdef int enrichment 
		if self.outfile_check(overwrite): 
			os.system("mkdir %s.vice" % (self.name)) 
			for i in range(self._mz[0].mig[0].n_zones): 
				os.system("mkdir %s.vice" % (self._zones[i].name)) 
			self.setup_migration() # used to be in self.prep

			# warn the user about r-process elements and bad solar calibrations 
			self._zones[0]._singlezone__c_version.nsns_warning() 
			self._zones[0]._singlezone__c_version.solar_z_warning() 

			# just do it #nike 
			enrichment = _multizone.multizone_evolve(self._mz) 
			self.pickle() 

			# save yield settings and attributes 
			for i in range(self._mz[0].mig[0].n_zones): 
				self._zones[i]._singlezone__c_version.pickle() 
		else: 
			_multizone.multizone_cancel(self._mz) 
			enrichment = 0 

		self.dealign_name_attributes() 
		if enrichment == 1: 
			_multizone.multizone_cancel(self._mz) 
			raise SystemError("Internal Error") 
		elif enrichment == 2: 
			_multizone.multizone_cancel(self._mz) 
			raise RuntimeError("""Sum of migration likelihoods for at least \
zone and at least one timestep larger than 1.""") 
		elif enrichment == 3: 
			raise IOError("Couldn't save tracer particle data.") 
		elif capture: 
			return output(self.name) 
		else: 
			pass 


	def prep(self, output_times): 
		""" 
		Prepares the simulation to be ran based on the current settings. 

		Parameters 
		========== 
		output_times :: array-like 
			The array of values the user passed to run() 

		Raises 
		====== 
		Exceptions raised by subroutines 

		Notes 
		===== 
		The order of function calls here is highly sensitive to memory errors. 
		It must go setup calls, then for loop, then migration setup. Anything 
		else messes with attributes and causes values to be reset 
		""" 
		self.align_element_attributes() 
		self.zone_alignment_warnings() 
		self.timestep_alignment_error() 
		for i in range(self._mz[0].mig[0].n_zones): 
			times = self._zones[i]._singlezone__zone_prep(output_times) 
			self._mz[0].zones[i][0].output_times = copy_pylist( 
				times)
			self._mz[0].zones[i][0].n_outputs = len(times) 


	def outfile_check(self, overwrite): 
		""" 
		Determines if any of the output files exist and proceeds according to 
		the user specified overwrite preference. 

		Parameters 
		========== 
		overwrite :: bool 
			The user's overwrite spefication - True to force overwrite. 

		Returns 
		======= 
		True if the simulation can proceed and run, overwriting any files that 
		may already exist. False if the user wishes to abort. 
		""" 
		if overwrite: 
			if os.path.exists("%s.vice" % (self.name)): 
				os.system("rm -rf %s.vice" % (self.name)) 
			else: 
				pass 
			return True 
		else: 
			if os.path.exists("%s.vice" % (self.name)): 
				""" 
				Output directory exists. Ask the user if they'd like to wipe 
				its contents and overwrite. 
				""" 
				answer = input("""\
Output directory already exists. Overwriting will delete all of its contents, \
leaving only the results of the current simulation.\nOutput directory: \
%s.vice\nOverwrite? (y | n) """ % (self.name)) 

				# be emphatic about it 
				while answer.lower() not in ["yes", "y", "no", "n"]: 
					answer = input("Please enter either 'y' or 'n': ") 

				if answer.lower() in ["y", "yes"]: 
					os.system("rm -rf %s.vice" % (self.name)) 
					return True 
				else: 
					return False 
			else: 
				return True 


	def setup_migration(self): 
		""" 
		Sets up both the gas and stellar migration for simulation 
		""" 
		self.setup_gas_migration() 
		self.setup_tracers() 


	def setup_gas_migration(self): 
		""" 
		Sets up the gas migration matrix for simulation. Cancels the simulation 
		if there's an error. 

		Raises 
		====== 
		RuntimeError :: 
			:: 	one of the migration specifications produces a value that is 
				not between 0 and 1 at any timestep. 
		""" 
		_migration.malloc_gas_migration(self._mz) 
		cdef long length = 10l + long(
			self._mz[0].zones[0].output_times[
				self._mz[0].zones[0].n_outputs - 1l] / 
			self._mz[0].zones[0].dt 
		) 
		eval_times = [i * self._mz[0].zones[0].dt for i in range(length)] 
		errmsg = """Migration probability must be between 0 and 1 at all \
timesteps.""" 

		for i in range(self._mz[0].mig[0].n_zones): 
			for j in range(self._mz[0].mig[0].n_zones): 
				""" 
				For both gas and stars, look at the i,j'th element of the 
				user-specified migration matrix. Whether it is a number or a 
				function, map it across the known evaluation times of the 
				simulation and pipe it to C 

				Notes 
				===== 
				Don't ignore i == j. In this case under-the-hood the migration 
				matrix will ALWAYS be zero. 
				""" 
				if isinstance(self.migration.gas[i][j], numbers.Number): 
					arr = length * [self.migration.gas[i][j]] 
					if _migration.setup_migration_element(self._mz[0], 
						self._mz[0].mig[0].gas_migration, 
						i, j, copy_pylist(arr)): 

						_multizone.multizone_cancel(self._mz) 
						raise RuntimeError(errmsg) 
					else: 
						pass  
			
				elif callable(self.migration.gas[i][j]): 
					arr = list(map(self.migration.gas[i][j], eval_times)) 
					if _migration.setup_migration_element(self._mz[0], 
						self._mz[0].mig[0].gas_migration, 
						i, j, copy_pylist(arr)): 

						_multizone.multizone_cancel(self._mz) 
						raise RuntimeError(errmsg) 
					else: 
						pass  
				else: 
					raise SystemError("Internal Error") 


	def setup_tracers(self): 
		""" 
		Setup the tracer zone histories according to the user's prescription 

		This will call the function of initial zone number, formation time, 
		and simulation time, and expect an int to be returned describing the 
		zone occupation number of that tracer particle at that time. 
		""" 
		n = _singlezone.n_timesteps(self._mz[0].zones[0][0]) 
		eval_times = [i * self._mz[0].zones[0][0].dt for i in range(n + 1)] 
		x = 0 
		takes_keyword = True 
		try: # check for an optional keyword argument 'n' 
			self.migration.stars(0, 0, 0, n = 0) 
		except TypeError: 
			takes_keyword = False 
		_tracer.malloc_tracers(self._mz) 
		if hasattr(self.migration.stars, "write"): 
			# Allow users to write extra data when the function is called. 
			try: 
				self.migration.stars.write = True 
			except: pass 

		for i in range(n): # for each timestep 
			for j in range(self.n_zones): # for each zone 
				for k in range(self.n_tracers): 
					kwargs = {} 
					if takes_keyword: kwargs["n"] = k 
					zone_history = n * [j] 
					if i <= n - _singlezone.BUFFER: 
						""" 
						For each timestep in the buffer, set the zone number 
						according to the user specification at that time. 
						""" 
						zone_history[i:(n - _singlezone.BUFFER)] = [
							self.migration.stars(j, 
								i * self._mz[0].zones[0][0].dt, 
								l, **kwargs) for l in eval_times[i:(n - 
									_singlezone.BUFFER + 1)]
						] 

						""" 
						For each timestep in the buffer, set the zone number 
						according to the user specification at the actual 
						final timestep. 
						""" 
						zone_history[-_singlezone.BUFFER:] = (
							_singlezone.BUFFER) * [zone_history[-(
								_singlezone.BUFFER + 1)]
						] 
					else: 
						""" 
						For those that form in the buffer, set their zone 
						number to the zone of origin always. 
						""" 
						pass 

					# error handling, then send it down to C 
					self.check_zone_history(zone_history, i, j) 
					zone_history = [int(l) for l in zone_history] 
					self.copy_zone_history(zone_history, x, i, n) 
					x += 1 # increment tracer particle index 
			if self.verbose: 
				sys.stdout.write("""Setting up star particles. \
Progress: %.1f%%\r""" % (100 * (i + 1) / n)) 
				sys.stdout.flush() 
			else: pass 
		if self.verbose: sys.stdout.write("\n") 

		if hasattr(self.migration.stars, "write"): 
			# revert write attribute to False 
			try: 
				self.migration.stars.write = False 
			except: pass 


	def check_zone_history(self, zones, timestep_origin, zone_origin): 
		""" 
		Ensures that the zone history mapped across time that the user has 
		specified maps to integers between 0 and self.n_zones - 1, and raises 
		an exception if necessary. 

		Parameters 
		========== 
		zones :: list 
			The tracer particle's zone occupation number evaluated at all 
			timesteps 
		timestep_origin :: int 
			The timestep at which the tracer particle will form 
		zone_origin :: int 
			The zone number in which the tracer particle will form 
		""" 
		if not all(map(lambda x: isinstance(x, numbers.Number), zones)): 
			raise TypeError("""Zone history for tracer particle mapped to \
non-numerical value.""") 
		elif not all(map(lambda x: x % 1 == 0, zones)): 
			raise ValueError("""Zone history for tracer particle must be an \
integer.""") 
		elif not all(map(lambda x: 0 <= x < self.n_zones, zones)): 
			raise ValueError("""All zone numbers must be between 0 and \
self.n_zones - 1 (inclusive).""") 
		elif zones[timestep_origin] != zone_origin: 
			raise ValueError("""Tracer particle's zone history, evaluated at \
its time of formation, must equal its zone of origin.""") 
		else: 
			pass 


	def copy_zone_history(self, zones, idx, formation_timestep, 
		n_timesteps): 
		""" 
		Copies a tracer particle's zone history to the pointer in C. 

		Parameters 
		========== 
		zones :: list 
			The zone numbers the tracer particle occupies at all timesteps 
		idx :: int 
			The tracer particle's index 
		formation_timestep :: int 
			The timestep number at which the tracer particle will form 
		n_timesteps :: int 
			The number of timesteps the simulation will evaluate at, counting 
			the 10-timestep memory buffer. 
		""" 
		self._mz[0].mig[0].tracers[idx][0].zone_history = <int *> malloc (
			n_timesteps * sizeof(int)) 
		for i in range(n_timesteps): 
			if i < formation_timestep: 
				# zone number is -1 until it forms 
				self._mz[0].mig[0].tracers[idx][0].zone_history[i] = -1 
			else: 
				self._mz[0].mig[0].tracers[idx][0].zone_history[i] = zones[i] 

		# more bookkeeping 
		self._mz[0].mig[0].tracers[idx][0].timestep_origin = formation_timestep 
		self._mz[0].mig[0].tracers[idx][0].zone_origin = int(
			zones[formation_timestep])
		if self.simple: 
			self._mz[0].mig[0].tracers[idx][0].zone_current = int(
				zones[n_timesteps - _singlezone.BUFFER]) 
		else: 
			self._mz[0].mig[0].tracers[idx][0].zone_current = int(
				zones[formation_timestep])


	def align_name_attributes(self): 
		""" 
		Checks for duplicate names within the zone attribues and raises a 
		RuntimeError if there are duplicates. Then puts the multizone object's 
		name in front of each zone's name. This ensures that the singlezone 
		objects will open files at paths of the format: 

		multizonemodel.vice/onezonemodel.vice/ 

		Checks for duplicate names as well 
		""" 
		# Start with a list of each zone's names and remove duplicates 
		names = [self._zones[i].name for i in range(self._mz[0].mig[0].n_zones)] 
		names = list(dict.fromkeys(names)) 
		if len(names) < self._mz[0].mig[0].n_zones: 
			raise RuntimeError("Zones with duplicate names detected.") 
		else: 
			# put multizone's name in front of each zone's name 
			for i in range(self._mz[0].mig[0].n_zones): 
				self._zones[i].name = "%s.vice/%s" % (self.name, names[i]) 


	def dealign_name_attributes(self): 
		""" 
		Removes the multizone model's name from the front of each zone's name 
		at the end of a multizone simulation. 
		""" 
		for i in range(self._mz[0].mig[0].n_zones): 
			self._zones[i].name = self._zones[i].name.split('/')[-1] 


	def align_element_attributes(self): 
		""" 
		Sets each zone's elements attribute to the union of all of them. 
		""" 
		# take a snapshot of each zone's elements and start w/zone 0 
		elements_attributes = [self._zones[i].elements for i in range(
			self._mz[0].mig[0].n_zones)] 
		elements = list(elements_attributes[0][:]) 

		# if any zone has an element not in the list, append it 
		for i in range(1, self._mz[0].mig[0].n_zones): 
			for j in elements_attributes[i]: 
				if j not in elements: 
					elements.append(j) 
				else: 
					continue 

		# Set each zone's elements to the newly determined union 
		for i in range(self._mz[0].mig[0].n_zones): 
			self._zones[i].elements = elements 


	def zone_alignment_warnings(self): 
		""" 
		Raises ScienceWarnings if any of a number of attributes differ between 
		zones. 
		""" 
		n_zones = self._mz[0].mig[0].n_zones 

		# attributes that shouldn't (but can) differ between zones 
		attrs = { 
			"IMF": 			[self._zones[i].IMF for i in range(n_zones)], 
			"recycling":	[self._zones[i].recycling for i in range(n_zones)], 
			"delay": 		[self._zones[i].delay for i in range(n_zones)], 
			"RIa": 			[self._zones[i].RIa for i in range(n_zones)], 
			"schmidt": 		[self._zones[i].schmidt for i in range(n_zones)], 
			"schmidt_index": [self._zones[i].schmidt_index for i in range(
				n_zones)], 
			"MgSchmidt": 	[self._zones[i].MgSchmidt for i in range(n_zones)], 
			"m_upper": 		[self._zones[i].m_upper for i in range(n_zones)], 
			"m_lower": 		[self._zones[i].m_lower for i in range(n_zones)], 
			"Z_solar": 		[self._zones[i].Z_solar for i in range(n_zones)], 
			"agb_model": 	[self._zones[i].agb_model for i in range(n_zones)] 
		} 


		def checker(key): 
			"""
			Detects any non-uniformity across zones and raises ScienceWarning 
			""" 
			if len(list(dict.fromkeys(attrs[key]))) > 1: 
				warnings.warn("""\
Attribute '%s' is not uniform across zones. This will introduce numerical \
artifacts.""" % (key), ScienceWarning)  
			else: 
				pass 

		for i in attrs.keys(): 
			checker(i) 


	def timestep_alignment_error(self): 
		""" 
		Raises a Runtime Error if the timestep size is not uniform across 
		zones. 
		""" 
		timestep_size_checker = list(dict.fromkeys(
			[self._zones[i].dt for i in range(self._mz[0].mig[0].n_zones)] 
		)) 
		if len(timestep_size_checker) > 1: 
			raise RuntimeError("Timestep size not uniform across zones.") 
		else: 
			pass 


	def pickle(self): 
		""" 
		Saves the parameters of this object in a series of pickles. A 
		copy of the nucleosynthetic yields is not necessary, as they are 
		saved by the singlezone object anyway. 

		Notes 
		===== 
		While this function serves as the writer, the reader is the 
		vice.multizone.from_output class method, implemented in python. 
		Any changes to this function should be reflected there. 

		See Also 
		======== 
		vice.core.pickles 
		""" 

		# First put the parameters in a jar 
		attrs = {
			"name": 			self.name, 
			"n_zones": 			self.n_zones, 
			"n_stars": 			self.n_tracers, 
			"simple": 			self.simple, 
			"verbose": 			self.verbose 
		} 
		attrs["zones"] = dict(zip(
			list(range(self.n_zones)), 
			[self.zones[i].name.split('/')[-1] for i in range(self.n_zones)] 
		)) 
		jar(attrs, name = "%s.vice/attributes" % (self.name)).close() 

		# Save the migration parameters to a series of jars 
		jar({"stars": self.migration.stars}, 
			name = "%s.vice/migration" % (self.name)).close() 
		for i in range(self.n_zones): 
			attrs = dict(zip(
				[str(i) for i in range(self.n_zones)], 
				self.migration.gas[i].tolist() 
			)) 
			jar(attrs, 
				name = "%s.vice/migration/gas%d" % (self.name, i)).close() 

