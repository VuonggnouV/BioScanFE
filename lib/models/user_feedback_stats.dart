class UserFeedbackStats {
  final String uid;
  final String username;
  final int totalScans;
  final int likes;
  final int dislikes;
  final int notRated;
  final double likeRate;
  final String role; // <-- Thêm dòng này

  UserFeedbackStats({
    required this.uid,
    required this.username,
    required this.totalScans,
    required this.likes,
    required this.dislikes,
    required this.notRated,
    required this.likeRate,
    required this.role, // <-- Thêm vào constructor
  });
}