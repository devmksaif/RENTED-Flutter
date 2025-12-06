class PaginationResponse {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationResponse({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationResponse.fromJson(Map<String, dynamic> json) {
    return PaginationResponse(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  bool get hasMore => currentPage < lastPage;
  bool get isLastPage => currentPage >= lastPage;
}
