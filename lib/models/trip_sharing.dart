/// A member of a trip's (future) collaboration list. Only [CollaboratorRole.owner]
/// is meaningful today — every trip has exactly one owner, the signed-in
/// account. Editors and viewers are modeled now so the data layer, sync
/// payloads, and conflict handling are already collaboration-shaped, but no
/// screen lets a family invite anyone yet.
enum CollaboratorRole { owner, editor, viewer }

extension CollaboratorRoleX on CollaboratorRole {
  String get label {
    switch (this) {
      case CollaboratorRole.owner:
        return 'Owner';
      case CollaboratorRole.editor:
        return 'Editor';
      case CollaboratorRole.viewer:
        return 'View only';
    }
  }
}

class TripCollaborator {
  final String id;
  final String name;
  final String email;
  final CollaboratorRole role;

  const TripCollaborator({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
      };

  factory TripCollaborator.fromJson(Map<String, dynamic> json) {
    return TripCollaborator(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: CollaboratorRole.values.byName(json['role'] as String),
    );
  }
}

/// Prepares each [Trip] for future collaboration without implementing
/// sharing itself: one owner, plus lists of editors and view-only members
/// that stay empty until an invite flow exists. [ConflictResolver] and the
/// sync payload already carry this shape so adding real invites later is a
/// UI-only change.
class TripSharing {
  final TripCollaborator owner;
  final List<TripCollaborator> editors;
  final List<TripCollaborator> viewers;

  const TripSharing({
    required this.owner,
    this.editors = const [],
    this.viewers = const [],
  });

  factory TripSharing.ownedBy(TripCollaborator owner) => TripSharing(owner: owner);

  bool get isShared => editors.isNotEmpty || viewers.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'owner': owner.toJson(),
        'editors': [for (final e in editors) e.toJson()],
        'viewers': [for (final v in viewers) v.toJson()],
      };

  factory TripSharing.fromJson(Map<String, dynamic> json) {
    return TripSharing(
      owner: TripCollaborator.fromJson(json['owner'] as Map<String, dynamic>),
      editors: [
        for (final e in (json['editors'] as List? ?? const []))
          TripCollaborator.fromJson(e as Map<String, dynamic>),
      ],
      viewers: [
        for (final v in (json['viewers'] as List? ?? const []))
          TripCollaborator.fromJson(v as Map<String, dynamic>),
      ],
    );
  }
}
