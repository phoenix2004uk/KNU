{
	LOCAL IshValue IS {
		PARAMETER A, B, Ishyness.
		RETURN A > B-Ishyness AND A < B+Ishyness.
	}.

	LOCAL IshFactor IS {
		PARAMETER A, B, Ishyness.
		RETURN A > B*Ishyness AND A < B*(2-Ishyness).
	}.

	export(Lex(
		"version", "1.0.3",
		"value", IshValue,
		"factor", IshFactor
	)).
}