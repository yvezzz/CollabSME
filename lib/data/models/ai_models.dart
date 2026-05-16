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
      id: json['id'],
      taskId: json['task'],
      riskPercentage: json['risk_percentage']?.toDouble() ?? 0.0,
      predictedDelayDays: json['predicted_delay_days'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      reasons: json['reasons'] ?? {},
      recommendations: json['recommendations'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
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
      id: json['id'],
      userId: json['user'],
      taskId: json['task'],
      prompt: json['prompt'],
      response: json['response'],
      modelUsed: json['model_used'],
      createdAt: DateTime.parse(json['created_at']),
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
      id: json['id'],
      userId: json['user'],
      projectId: json['project'],
      sentimentScore: json['sentiment_score']?.toDouble() ?? 0.0,
      fatigueScore: json['fatigue_score']?.toDouble() ?? 0.0,
      analysisPeriodStart: DateTime.parse(json['analysis_period_start']),
      analysisPeriodEnd: DateTime.parse(json['analysis_period_end']),
      keyInsights: json['key_insights'] ?? {},
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
      id: json['id'],
      taskId: json['task'],
      detectionType: json['detection_type'],
      triggerCommentId: json['trigger_comment'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      suggestedActions: json['suggested_actions'] ?? {},
      detectedAt: DateTime.parse(json['detected_at']),
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
