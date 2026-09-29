#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
// EXTRA BEGIN
typedef struct DartCObject *WireSyncRust2DartDco;
typedef struct WireSyncRust2DartSse {
  uint8_t *ptr;
  int32_t len;
} WireSyncRust2DartSse;

typedef int64_t DartPort;
typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);
void store_dart_post_cobject(DartPostCObjectFnType ptr);
// EXTRA END
typedef struct _Dart_Handle* Dart_Handle;

typedef struct wire_cst_list_prim_f_64_strict {
  double *ptr;
  int32_t len;
} wire_cst_list_prim_f_64_strict;

typedef struct wire_cst_list_list_prim_f_64_strict {
  struct wire_cst_list_prim_f_64_strict **ptr;
  int32_t len;
} wire_cst_list_list_prim_f_64_strict;

typedef struct wire_cst_list_prim_f_64_loose {
  double *ptr;
  int32_t len;
} wire_cst_list_prim_f_64_loose;

typedef struct wire_cst_list_prim_u_8_strict {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_strict;

typedef struct wire_cst_list_String {
  struct wire_cst_list_prim_u_8_strict **ptr;
  int32_t len;
} wire_cst_list_String;

typedef struct wire_cst_record_string_f_64 {
  struct wire_cst_list_prim_u_8_strict *field0;
  double field1;
} wire_cst_record_string_f_64;

typedef struct wire_cst_list_record_string_f_64 {
  struct wire_cst_record_string_f_64 *ptr;
  int32_t len;
} wire_cst_list_record_string_f_64;

typedef struct wire_cst_graph_point {
  double x;
  double y;
  bool valid;
} wire_cst_graph_point;

typedef struct wire_cst_list_graph_point {
  struct wire_cst_graph_point *ptr;
  int32_t len;
} wire_cst_list_graph_point;

typedef struct wire_cst_matrix_result {
  bool success;
  struct wire_cst_list_prim_f_64_strict *data;
  uintptr_t rows;
  uintptr_t cols;
  double *scalar;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_matrix_result;

typedef struct wire_cst_list_matrix_result {
  struct wire_cst_matrix_result *ptr;
  int32_t len;
} wire_cst_list_matrix_result;

typedef struct wire_cst_list_prim_u_64_strict {
  uint64_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_64_strict;

typedef struct wire_cst_record_f_64_f_64 {
  double field0;
  double field1;
} wire_cst_record_f_64_f_64;

typedef struct wire_cst_list_record_f_64_f_64 {
  struct wire_cst_record_f_64_f_64 *ptr;
  int32_t len;
} wire_cst_list_record_f_64_f_64;

typedef struct wire_cst_unit_result {
  bool success;
  double value;
  struct wire_cst_list_prim_u_8_strict *from_unit;
  struct wire_cst_list_prim_u_8_strict *to_unit;
  struct wire_cst_list_prim_u_8_strict *formula;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_unit_result;

typedef struct wire_cst_list_unit_result {
  struct wire_cst_unit_result *ptr;
  int32_t len;
} wire_cst_list_unit_result;

typedef struct wire_cst_calculus_result {
  bool success;
  double value;
  struct wire_cst_list_prim_u_8_strict *symbolic;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_calculus_result;

typedef struct wire_cst_complex_result {
  bool success;
  double real;
  double imag;
  double magnitude;
  double angle_rad;
  double angle_deg;
  struct wire_cst_list_prim_u_8_strict *formatted_rect;
  struct wire_cst_list_prim_u_8_strict *formatted_polar;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_complex_result;

typedef struct wire_cst_confidence_interval_result {
  bool success;
  double lower;
  double upper;
  double center;
  double margin_of_error;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_confidence_interval_result;

typedef struct wire_cst_correlation_result {
  bool success;
  double correlation;
  double covariance;
  double p_value;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_correlation_result;

typedef struct wire_cst_discrete_result {
  bool success;
  uint64_t value;
  struct wire_cst_list_prim_u_8_strict *big_value;
  struct wire_cst_list_prim_u_64_strict *values;
  bool *bool_result;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_discrete_result;

typedef struct wire_cst_distribution_result {
  bool success;
  double pdf;
  double cdf;
  double mean;
  double variance;
  double std_dev;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_distribution_result;

typedef struct wire_cst_expression_result {
  bool success;
  double value;
  struct wire_cst_list_prim_u_8_strict *error;
  struct wire_cst_list_prim_u_8_strict *formatted;
} wire_cst_expression_result;

typedef struct wire_cst_graph_result {
  bool success;
  struct wire_cst_list_graph_point *points;
  double x_min;
  double x_max;
  double y_min;
  double y_max;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_graph_result;

typedef struct wire_cst_hypothesis_test_result {
  bool success;
  double test_statistic;
  double p_value;
  double critical_value;
  bool reject_null;
  struct wire_cst_record_f_64_f_64 confidence_interval;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_hypothesis_test_result;

typedef struct wire_cst_matrix_decomposition {
  bool success;
  struct wire_cst_list_prim_u_8_strict *decomposition_type;
  struct wire_cst_list_matrix_result *matrices;
  struct wire_cst_list_String *labels;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_matrix_decomposition;

typedef struct wire_cst_record_list_record_f_64_f_64_list_record_f_64_f_64 {
  struct wire_cst_list_record_f_64_f_64 *field0;
  struct wire_cst_list_record_f_64_f_64 *field1;
} wire_cst_record_list_record_f_64_f_64_list_record_f_64_f_64;

typedef struct wire_cst_regression_result {
  bool success;
  struct wire_cst_list_prim_f_64_strict *coefficients;
  double r_squared;
  struct wire_cst_list_prim_f_64_strict *residuals;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_regression_result;

typedef struct wire_cst_solve_result {
  bool success;
  struct wire_cst_list_prim_f_64_strict *roots;
  uintptr_t iterations;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_solve_result;

typedef struct wire_cst_statistics_result {
  bool success;
  struct wire_cst_list_record_string_f_64 *values;
  struct wire_cst_list_prim_u_8_strict *error;
} wire_cst_statistics_result;

void frbgen_kivixa_wire__crate__api__anova(int64_t port_,
                                           struct wire_cst_list_list_prim_f_64_strict *groups,
                                           double alpha);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__catalan(uint64_t n);

void frbgen_kivixa_wire__crate__api__chi_squared_test(int64_t port_,
                                                      struct wire_cst_list_prim_f_64_loose *observed,
                                                      struct wire_cst_list_prim_f_64_loose *expected,
                                                      double alpha);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__combinations(uint64_t n, uint64_t r);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__complex_convert(double real,
                                                                     double imag,
                                                                     bool to_polar);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__complex_operation(double a_real,
                                                                       double a_imag,
                                                                       double b_real,
                                                                       double b_imag,
                                                                       struct wire_cst_list_prim_u_8_strict *operation);

void frbgen_kivixa_wire__crate__api__compute_limit(int64_t port_,
                                                   struct wire_cst_list_prim_u_8_strict *expression,
                                                   struct wire_cst_list_prim_u_8_strict *variable,
                                                   double approach_value,
                                                   bool from_left,
                                                   bool from_right);

void frbgen_kivixa_wire__crate__api__compute_statistics(int64_t port_,
                                                        struct wire_cst_list_prim_f_64_loose *data);

void frbgen_kivixa_wire__crate__api__confidence_interval_mean(int64_t port_,
                                                              struct wire_cst_list_prim_f_64_loose *data,
                                                              double confidence_level);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__confidence_interval_proportion(uint64_t successes,
                                                                                    uint64_t n,
                                                                                    double confidence_level);

void frbgen_kivixa_wire__crate__api__confidence_interval_variance(int64_t port_,
                                                                  struct wire_cst_list_prim_f_64_loose *data,
                                                                  double confidence_level);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__convert_number_system(struct wire_cst_list_prim_u_8_strict *value,
                                                                           uint32_t from_base,
                                                                           uint32_t to_base);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__convert_to_all_units(double value,
                                                                          struct wire_cst_list_prim_u_8_strict *from_unit);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__convert_unit(double value,
                                                                  struct wire_cst_list_prim_u_8_strict *from_unit,
                                                                  struct wire_cst_list_prim_u_8_strict *to_unit);

void frbgen_kivixa_wire__crate__api__correlation_covariance(int64_t port_,
                                                            struct wire_cst_list_prim_f_64_loose *x,
                                                            struct wire_cst_list_prim_f_64_loose *y);

void frbgen_kivixa_wire__crate__api__derivative_graph(int64_t port_,
                                                      struct wire_cst_list_prim_u_8_strict *expression,
                                                      struct wire_cst_list_prim_u_8_strict *variable,
                                                      struct wire_cst_list_prim_f_64_loose *x_values);

void frbgen_kivixa_wire__crate__api__differentiate(int64_t port_,
                                                   struct wire_cst_list_prim_u_8_strict *expression,
                                                   struct wire_cst_list_prim_u_8_strict *variable,
                                                   double point,
                                                   uint32_t order);

void frbgen_kivixa_wire__crate__api__distribution_compute(int64_t port_,
                                                          struct wire_cst_list_prim_u_8_strict *distribution_type,
                                                          struct wire_cst_list_prim_f_64_loose *params,
                                                          double x);

void frbgen_kivixa_wire__crate__api__double_integral(int64_t port_,
                                                     struct wire_cst_list_prim_u_8_strict *expression,
                                                     struct wire_cst_list_prim_u_8_strict *x_var,
                                                     struct wire_cst_list_prim_u_8_strict *y_var,
                                                     double x_min,
                                                     double x_max,
                                                     double y_min,
                                                     double y_max,
                                                     uint32_t num_intervals);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__euler_totient(uint64_t n);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__evaluate_expression(struct wire_cst_list_prim_u_8_strict *expression);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__evaluate_formula(struct wire_cst_list_prim_u_8_strict *formula,
                                                                      struct wire_cst_list_String *variables,
                                                                      struct wire_cst_list_prim_f_64_loose *values);

void frbgen_kivixa_wire__crate__api__evaluate_graph_points(int64_t port_,
                                                           struct wire_cst_list_prim_u_8_strict *expression,
                                                           struct wire_cst_list_prim_u_8_strict *variable,
                                                           struct wire_cst_list_prim_f_64_loose *x_values);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__factorial(uint64_t n);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__fibonacci(uint64_t n);

void frbgen_kivixa_wire__crate__api__find_extrema(int64_t port_,
                                                  struct wire_cst_list_prim_u_8_strict *expression,
                                                  struct wire_cst_list_prim_u_8_strict *variable,
                                                  double x_min,
                                                  double x_max,
                                                  uintptr_t num_samples);

void frbgen_kivixa_wire__crate__api__find_graph_roots(int64_t port_,
                                                      struct wire_cst_list_prim_u_8_strict *expression,
                                                      struct wire_cst_list_prim_u_8_strict *variable,
                                                      double x_min,
                                                      double x_max,
                                                      uintptr_t num_samples);

void frbgen_kivixa_wire__crate__api__find_roots_in_interval(int64_t port_,
                                                            struct wire_cst_list_prim_u_8_strict *expression,
                                                            struct wire_cst_list_prim_u_8_strict *variable,
                                                            double start,
                                                            double end,
                                                            uint32_t num_samples);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__gcd(uint64_t a, uint64_t b);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__generate_x_range(double start,
                                                                      double end,
                                                                      uintptr_t num_points);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__get_constant(struct wire_cst_list_prim_u_8_strict *name);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__get_unit_categories(void);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__get_units_for_category(struct wire_cst_list_prim_u_8_strict *category);

void frbgen_kivixa_wire__crate__api__gradient(int64_t port_,
                                              struct wire_cst_list_prim_u_8_strict *expression,
                                              struct wire_cst_list_String *variables,
                                              struct wire_cst_list_record_string_f_64 *point);

void frbgen_kivixa_wire__crate__api__init_app(int64_t port_);

void frbgen_kivixa_wire__crate__api__integral_graph(int64_t port_,
                                                    struct wire_cst_list_prim_u_8_strict *expression,
                                                    struct wire_cst_list_prim_u_8_strict *variable,
                                                    struct wire_cst_list_prim_f_64_loose *x_values,
                                                    double initial_value);

void frbgen_kivixa_wire__crate__api__integrate(int64_t port_,
                                               struct wire_cst_list_prim_u_8_strict *expression,
                                               struct wire_cst_list_prim_u_8_strict *variable,
                                               double lower,
                                               double upper,
                                               uint32_t num_intervals);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__is_perfect(uint64_t n);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__is_prime(uint64_t n);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__lcm(uint64_t a, uint64_t b);

void frbgen_kivixa_wire__crate__api__line_integral(int64_t port_,
                                                   struct wire_cst_list_prim_u_8_strict *expression,
                                                   struct wire_cst_list_prim_u_8_strict *x_param,
                                                   struct wire_cst_list_prim_u_8_strict *y_param,
                                                   struct wire_cst_list_prim_u_8_strict *t_var,
                                                   double t_min,
                                                   double t_max,
                                                   uint32_t num_intervals);

void frbgen_kivixa_wire__crate__api__linear_regression(int64_t port_,
                                                       struct wire_cst_list_prim_f_64_loose *x_data,
                                                       struct wire_cst_list_prim_f_64_loose *y_data);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__list_divisors(uint64_t n);

void frbgen_kivixa_wire__crate__api__matrix_decomposition(int64_t port_,
                                                          struct wire_cst_list_prim_f_64_loose *data,
                                                          uintptr_t rows,
                                                          uintptr_t cols,
                                                          struct wire_cst_list_prim_u_8_strict *decomposition_type);

void frbgen_kivixa_wire__crate__api__matrix_operation(int64_t port_,
                                                      struct wire_cst_list_prim_f_64_loose *a_data,
                                                      uintptr_t a_rows,
                                                      uintptr_t a_cols,
                                                      struct wire_cst_list_prim_f_64_strict *b_data,
                                                      uintptr_t *b_rows,
                                                      uintptr_t *b_cols,
                                                      struct wire_cst_list_prim_u_8_strict *operation);

void frbgen_kivixa_wire__crate__api__matrix_properties(int64_t port_,
                                                       struct wire_cst_list_prim_f_64_loose *data,
                                                       uintptr_t rows,
                                                       uintptr_t cols);

void frbgen_kivixa_wire__crate__api__matrix_rref(int64_t port_,
                                                 struct wire_cst_list_prim_f_64_loose *data,
                                                 uintptr_t rows,
                                                 uintptr_t cols);

void frbgen_kivixa_wire__crate__api__mixed_partial_derivative(int64_t port_,
                                                              struct wire_cst_list_prim_u_8_strict *expression,
                                                              struct wire_cst_list_prim_u_8_strict *var1,
                                                              struct wire_cst_list_prim_u_8_strict *var2,
                                                              struct wire_cst_list_record_string_f_64 *point);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_add(uint64_t a, uint64_t b, uint64_t m);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_divide(uint64_t a, uint64_t b, uint64_t m);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_inverse(uint64_t a, uint64_t m);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_multiply(uint64_t a,
                                                                  uint64_t b,
                                                                  uint64_t m);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_pow(uint64_t base,
                                                             uint64_t exp,
                                                             uint64_t modulus);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__mod_sub(uint64_t a, uint64_t b, uint64_t m);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__parse_formula(struct wire_cst_list_prim_u_8_strict *formula);

void frbgen_kivixa_wire__crate__api__partial_derivative(int64_t port_,
                                                        struct wire_cst_list_prim_u_8_strict *expression,
                                                        struct wire_cst_list_prim_u_8_strict *variable,
                                                        struct wire_cst_list_record_string_f_64 *point,
                                                        uint32_t order);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__permutations(uint64_t n, uint64_t r);

void frbgen_kivixa_wire__crate__api__polynomial_regression(int64_t port_,
                                                           struct wire_cst_list_prim_f_64_loose *x_data,
                                                           struct wire_cst_list_prim_f_64_loose *y_data,
                                                           uintptr_t degree);

WireSyncRust2DartDco frbgen_kivixa_wire__crate__api__prime_factors(uint64_t n);

void frbgen_kivixa_wire__crate__api__sieve_primes(int64_t port_, uint64_t n);

void frbgen_kivixa_wire__crate__api__solve_equation(int64_t port_,
                                                    struct wire_cst_list_prim_u_8_strict *expression,
                                                    struct wire_cst_list_prim_u_8_strict *variable,
                                                    double initial_guess,
                                                    double tolerance,
                                                    uint32_t max_iterations);

void frbgen_kivixa_wire__crate__api__t_test(int64_t port_,
                                            struct wire_cst_list_prim_f_64_loose *data,
                                            double hypothesized_mean,
                                            double alpha);

void frbgen_kivixa_wire__crate__api__taylor_coefficients(int64_t port_,
                                                         struct wire_cst_list_prim_u_8_strict *expression,
                                                         struct wire_cst_list_prim_u_8_strict *variable,
                                                         double around,
                                                         uint32_t num_terms);

void frbgen_kivixa_wire__crate__api__triple_integral(int64_t port_,
                                                     struct wire_cst_list_prim_u_8_strict *expression,
                                                     struct wire_cst_list_prim_u_8_strict *x_var,
                                                     struct wire_cst_list_prim_u_8_strict *y_var,
                                                     struct wire_cst_list_prim_u_8_strict *z_var,
                                                     double x_min,
                                                     double x_max,
                                                     double y_min,
                                                     double y_max,
                                                     double z_min,
                                                     double z_max,
                                                     uint32_t num_intervals);

void frbgen_kivixa_wire__crate__api__two_sample_t_test(int64_t port_,
                                                       struct wire_cst_list_prim_f_64_loose *data1,
                                                       struct wire_cst_list_prim_f_64_loose *data2,
                                                       double alpha);

void frbgen_kivixa_wire__crate__api__two_sample_z_test(int64_t port_,
                                                       struct wire_cst_list_prim_f_64_loose *data1,
                                                       struct wire_cst_list_prim_f_64_loose *data2,
                                                       double std1,
                                                       double std2,
                                                       double alpha);

void frbgen_kivixa_wire__crate__api__z_test(int64_t port_,
                                            struct wire_cst_list_prim_f_64_loose *data,
                                            double hypothesized_mean,
                                            double population_std,
                                            double alpha);

bool *frbgen_kivixa_cst_new_box_autoadd_bool(bool value);

double *frbgen_kivixa_cst_new_box_autoadd_f_64(double value);

uintptr_t *frbgen_kivixa_cst_new_box_autoadd_usize(uintptr_t value);

struct wire_cst_list_String *frbgen_kivixa_cst_new_list_String(int32_t len);

struct wire_cst_list_graph_point *frbgen_kivixa_cst_new_list_graph_point(int32_t len);

struct wire_cst_list_list_prim_f_64_strict *frbgen_kivixa_cst_new_list_list_prim_f_64_strict(int32_t len);

struct wire_cst_list_matrix_result *frbgen_kivixa_cst_new_list_matrix_result(int32_t len);

struct wire_cst_list_prim_f_64_loose *frbgen_kivixa_cst_new_list_prim_f_64_loose(int32_t len);

struct wire_cst_list_prim_f_64_strict *frbgen_kivixa_cst_new_list_prim_f_64_strict(int32_t len);

struct wire_cst_list_prim_u_64_strict *frbgen_kivixa_cst_new_list_prim_u_64_strict(int32_t len);

struct wire_cst_list_prim_u_8_strict *frbgen_kivixa_cst_new_list_prim_u_8_strict(int32_t len);

struct wire_cst_list_record_f_64_f_64 *frbgen_kivixa_cst_new_list_record_f_64_f_64(int32_t len);

struct wire_cst_list_record_string_f_64 *frbgen_kivixa_cst_new_list_record_string_f_64(int32_t len);

struct wire_cst_list_unit_result *frbgen_kivixa_cst_new_list_unit_result(int32_t len);
static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_box_autoadd_bool);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_box_autoadd_f_64);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_box_autoadd_usize);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_String);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_graph_point);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_list_prim_f_64_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_matrix_result);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_f_64_loose);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_f_64_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_u_64_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_prim_u_8_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_record_f_64_f_64);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_record_string_f_64);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_cst_new_list_unit_result);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__anova);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__catalan);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__chi_squared_test);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__combinations);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__complex_convert);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__complex_operation);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__compute_limit);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__compute_statistics);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__confidence_interval_mean);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__confidence_interval_proportion);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__confidence_interval_variance);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__convert_number_system);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__convert_to_all_units);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__convert_unit);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__correlation_covariance);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__derivative_graph);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__differentiate);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__distribution_compute);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__double_integral);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__euler_totient);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__evaluate_expression);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__evaluate_formula);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__evaluate_graph_points);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__factorial);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__fibonacci);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__find_extrema);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__find_graph_roots);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__find_roots_in_interval);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__gcd);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__generate_x_range);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__get_constant);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__get_unit_categories);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__get_units_for_category);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__gradient);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__init_app);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__integral_graph);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__integrate);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__is_perfect);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__is_prime);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__lcm);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__line_integral);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__linear_regression);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__list_divisors);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__matrix_decomposition);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__matrix_operation);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__matrix_properties);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__matrix_rref);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mixed_partial_derivative);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_add);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_divide);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_inverse);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_multiply);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_pow);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__mod_sub);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__parse_formula);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__partial_derivative);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__permutations);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__polynomial_regression);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__prime_factors);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__sieve_primes);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__solve_equation);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__t_test);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__taylor_coefficients);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__triple_integral);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__two_sample_t_test);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__two_sample_z_test);
    dummy_var ^= ((int64_t) (void*) frbgen_kivixa_wire__crate__api__z_test);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}
