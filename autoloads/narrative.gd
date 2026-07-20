extends Node

signal found_fragment(data: Dictionary)

var fragments := {
	"frag_01": {
		"zone": "port_exterieur",
		"text": "SOLINE — maître de port adjoint, 1881-1887",
		"ida_comment": "Son nom. Sur une plaque officielle. Je ne m'y attendais pas.",
		"tone": "troubled",
		"found": false,
		"layer": 3
	},
	"frag_07": {
		"zone": "rues_commercantes",
		"text": "Registre de l'épicerie Aurel & Fils — semaine du 14 au 21 mars",
		"ida_comment": "Aurel. Le nom de famille de ma grand-mère avant le mariage. C'est ici.",
		"tone": "troubled",
		"found": false,
		"layer": 3
	},
}

func find_fragment(id: String) -> void:
	if fragments.has(id) and not fragments[id]["found"]:
		fragments[id]["found"] = true
		found_fragment.emit(fragments[id])
