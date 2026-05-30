class AIPredictionModel {
  final int id;
  final int taskId;
  final double riskPercentage;
  final int? predictedDelayDays;
  final double confidence;
  final Map<String, dynamic> reasons;
  final Map<String, dynamic> recommendations;
  final DateTime createdAt;
  final bool isResolved;

  AIPredictionModel({
    required this.id,
    required this.taskId,
    required this.riskPercentage,
    this.predictedDelayDays,
    required this.confidence,
    required this.reasons,
    required this.recommendations,
    required this.createdAt,
    required this.isResolved,
  });

  factory AIPredictionModel.fromJson(Map<String, dynamic> json) {
    return AIPredictionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      taskId: json['task'] is int ? json['task'] as int : int.tryParse(json['task']?.toString() ?? '0') ?? 0,
      riskPercentage: (json['risk_percentage'] is num ? (json['risk_percentage'] as num).toDouble() : double.tryParse(json['risk_percentage']?.toString() ?? '0') ?? 0.0),
      predictedDelayDays: json['predicted_delay_days'] is int ? json['predicted_delay_days'] as int : int.tryParse(json['predicted_delay_days']?.toString() ?? ''),
      confidence: (json['confidence'] is num ? (json['confidence'] as num).toDouble() : double.tryParse(json['confidence']?.toString() ?? '0') ?? 0.0),
      reasons: json['reasons'] is Map ? json['reasons'] as Map<String, dynamic> : {},
      recommendations: json['recommendations'] is Map ? json['recommendations'] as Map<String, dynamic> : {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isResolved: json['is_resolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': taskId,
      'risk_percentage': riskPercentage,
      'predicted_delay_days': predictedDelayDays,
      'confidence': confidence,
      'reasons': reasons,
      'recommendations': recommendations,
      'created_at': createdAt.toIso8601String(),
      'is_resolved': isResolved,
    };
  }
}

class AIGenerationLogModel {
  final int id;
  final int userId;
  final int? taskId;
  final String prompt;
  final String response;
  final String modelUsed;
  final DateTime createdAt;

  AIGenerationLogModel({
    required this.id,
    required this.userId,
    this.taskId,
    required this.prompt,
    required this.response,
    required this.modelUsed,
    required this.createdAt,
  });

  factory AIGenerationLogModel.fromJson(Map<String, dynamic> json) {
    return AIGenerationLogModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user'] is int ? json['user'] as int : int.tryParse(json['user']?.toString() ?? '0') ?? 0,
      taskId: json['task'] is int ? json['task'] as int : int.tryParse(json['task']?.toString() ?? ''),
      prompt: json['prompt']?.toString() ?? '',
      response: json['response']?.toString() ?? '',
      modelUsed: json['model_used']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'task': taskId,
      'prompt': prompt,
      'response': response,
      'model_used': modelUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AISentimentAnalysisModel {
  final int id;
  final int userId;
  final int projectId;
  final double sentimentScore;
  final double fatigueScore;
  final DateTime analysisPeriodStart;
  final DateTime analysisPeriodEnd;
  final Map<String, dynamic> keyInsights;

  AISentimentAnalysisModel({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.sentimentScore,
    required this.fatigueScore,
    required this.analysisPeriodStart,
    required this.analysisPeriodEnd,
    required this.keyInsights,
  });

  factory AISentimentAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AISentimentAnalysisModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user'] is int ? json['user'] as int : int.tryParse(json['user']?.toString() ?? '0') ?? 0,
      projectId: json['project'] is int ? json['project'] as int : int.tryParse(json['project']?.toString() ?? '0') ?? 0,
      sentimentScore: (json['sentiment_score'] is num ? (json['sentiment_score'] as num).toDouble() : double.tryParse(json['sentiment_score']?.toString() ?? '0') ?? 0.0),
      fatigueScore: (json['fatigue_score'] is num ? (json['fatigue_score'] as num).toDouble() : double.tryParse(json['fatigue_score']?.toString() ?? '0') ?? 0.0),
      analysisPeriodStart: json['analysis_period_start'] != null ? DateTime.parse(json['analysis_period_start']) : DateTime.now(),
      analysisPeriodEnd: json['analysis_period_end'] != null ? DateTime.parse(json['analysis_period_end']) : DateTime.now(),
      keyInsights: json['key_insights'] is Map ? json['key_insights'] as Map<String, dynamic> : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'project': projectId,
      'sentiment_score': sentimentScore,
      'fatigue_score': fatigueScore,
      'analysis_period_start': analysisPeriodStart.toIso8601String(),
      'analysis_period_end': analysisPeriodEnd.toIso8601String(),
      'key_insights': keyInsights,
    };
  }
}

class AIBlockageDetectionModel {
  final int id;
  final int taskId;
  final String detectionType;
  final int? triggerCommentId;
  final double confidence;
  final Map<String, dynamic> suggestedActions;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  AIBlockageDetectionModel({
    required this.id,
    required this.taskId,
    required this.detectionType,
    this.triggerCommentId,
    required this.confidence,
    required this.suggestedActions,
    required this.detectedAt,
    this.resolvedAt,
  });

  factory AIBlockageDetectionModel.fromJson(Map<String, dynamic> json) {
    return AIBlockageDetectionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      taskId: json['task'] is int ? json['task'] as int : int.tryParse(json['task']?.toString() ?? '0') ?? 0,
      detectionType: json['detection_type']?.toString() ?? '',
      triggerCommentId: json['trigger_comment'] is int ? json['trigger_comment'] as int : int.tryParse(json['trigger_comment']?.toString() ?? ''),
      confidence: (json['confidence'] is num ? (json['confidence'] as num).toDouble() : double.tryParse(json['confidence']?.toString() ?? '0') ?? 0.0),
      suggestedActions: json['suggested_actions'] is Map ? json['suggested_actions'] as Map<String, dynamic> : {},
      detectedAt: json['detected_at'] != null ? DateTime.parse(json['detected_at']) : DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': taskId,
      'detection_type': detectionType,
      'trigger_comment': triggerCommentId,
      'confidence': confidence,
      'suggested_actions': suggestedActions,
      'detected_at': detectedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
