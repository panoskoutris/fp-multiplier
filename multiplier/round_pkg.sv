package round_pkg;

  typedef enum logic [2:0] {
      IEEE_near,
      IEEE_zero,
      IEEE_pinf,
      IEEE_ninf,
      near_up,
      away_zero
  } round_mode;

endpackage

