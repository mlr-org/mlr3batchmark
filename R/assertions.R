assert_param_values = function(x, n_learners = NULL, .var.name = vname(x)) {
  assert_list(x, len = n_learners, .var.name = .var.name)

  ok = every(x, function(x) {
    test_list(x) && every(x, test_list, names = "unique", null.ok = TRUE)
  })

  if (!ok) {
    stopf("'%s' must be a three-time nested list and the most inner list must be named", .var.name)
  }
  invisible(x)
}
