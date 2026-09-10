# ambiguous columns require an explicit selection

    Code
      read_avesperu_name_file(path)
    Condition
      Error in `read_avesperu_name_file()`:
      ! Select the scientific-name column number and whether the file has a header.

# app workload limits reject excessive rows and long names

    Code
      validate_app_input(data.frame(submitted_name = rep("Falco sparverius", 10001)))
    Condition
      Error in `validate_app_input()`:
      ! Submit at most 10,000 names per run.

---

    Code
      validate_app_input(data.frame(submitted_name = paste(rep("x", 201), collapse = "")))
    Condition
      Error in `validate_app_input()`:
      ! Names must contain at most 200 characters.

