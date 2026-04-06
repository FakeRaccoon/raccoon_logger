/// Utility functions for formatting sizes, times, and other data
class RaccoonFormatHelpers {
  /// Formats bytes into human-readable size (KB, MB, GB)
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Formats duration in milliseconds to human-readable string
  static String formatDuration(int milliseconds) {
    return '$milliseconds ms';
  }

  /// Formats DateTime to relative time (e.g., "2 minutes ago")
  /// or absolute time if older than 1 day
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // For older timestamps, show the actual date
      return _formatDateTime(timestamp);
    }
  }

  /// Formats DateTime to "HH:MM:SS" format
  static String formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Formats DateTime to "MMM dd, HH:MM:SS" format
  static String _formatDateTime(DateTime timestamp) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${formatTime(timestamp)}';
  }

  /// Gets a status message for HTTP status codes
  static String getStatusMessage(int? statusCode) {
    if (statusCode == null) return 'Pending';
    if (statusCode == -1) return 'Failed';

    // Common status codes
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        if (statusCode >= 200 && statusCode < 300) {
          return 'Success';
        } else if (statusCode >= 300 && statusCode < 400) {
          return 'Redirect';
        } else if (statusCode >= 400 && statusCode < 500) {
          return 'Client Error';
        } else if (statusCode >= 500) {
          return 'Server Error';
        }
        return 'Unknown';
    }
  }
}
