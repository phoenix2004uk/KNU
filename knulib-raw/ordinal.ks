{
	function NORMALVEC { return VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION). }
	function RADIALVEC { return VXCL(PROGRADE:VECTOR, UP:VECTOR). }
	function RelativeSunVector { parameter vec is V(0,1,0). return LOOKDIRUP(vec,SUN:position). }

	export(Lex(
		"version", "1.0.0",
		"normal", NORMALVEC@,
		"radial", RADIALVEC@,
		"sun", RelativeSunVector@
	)).
}