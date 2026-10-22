extends RefCounted
## Three stars per voyage (Olivier, 2026-10-22), from the score (which already counts the cargo,
## a dry hull and arriving early). One star for delivering at all; two and three for good and great
## scores. Each contract can set its own thresholds; otherwise they come from what it pays.

const STAR_SHARES := [0.0, 0.55, 0.8] ## share of a "great run" score needed for stars 1..3


## The scores for 1, 2 and 3 stars. A great run: all crates, a dry hull, a quarter of the time spare.
static func thresholds(contract: Resource, crates: int) -> Array[int]:
	if contract.star_scores.size() == 3:
		var fixed: Array[int] = []
		for value in contract.star_scores:
			fixed.append(int(value))
		return fixed
	var great := crates * int(contract.pay_per_crate) + 200 + roundi(contract.deadline * 0.25 * 2.0)
	var result: Array[int] = [1]
	for share in [STAR_SHARES[1], STAR_SHARES[2]]:
		result.append(roundi(great * share / 10.0) * 10)
	return result


## Stars earned: none if the cargo wasn't delivered.
static func count(total: int, delivered: bool, limits: Array) -> int:
	if not delivered:
		return 0
	var stars := 0
	for limit in limits:
		if total >= int(limit):
			stars += 1
	return stars
