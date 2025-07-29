class SessonChatHistoryModel {
  bool? success;
  Session? session;
  List<Messages>? messages;
  Pagination? pagination;

  SessonChatHistoryModel(
      {this.success, this.session, this.messages, this.pagination});

  SessonChatHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    session =
    json['session'] != null ? new Session.fromJson(json['session']) : null;
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.session != null) {
      data['session'] = this.session!.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Session {
  String? id;
  String? title;
  Persona? persona;

  Session({this.id, this.title, this.persona});

  Session.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    persona =
    json['persona'] != null ? new Persona.fromJson(json['persona']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    if (this.persona != null) {
      data['persona'] = this.persona!.toJson();
    }
    return data;
  }
}

class Persona {
  int? id;
  String? name;
  String? title;
  String? avatar;

  Persona({this.id, this.name, this.title, this.avatar});

  Persona.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    title = json['title'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['title'] = this.title;
    data['avatar'] = this.avatar;
    return data;
  }
}

class Messages {
  int? id;
  String? content;
  bool? isUser;
  String? createdAt;

  Messages({this.id, this.content, this.isUser, this.createdAt});

  Messages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    content = json['content'];
    isUser = json['is_user'];
    createdAt = json['created_at'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['content'] = this.content;
    data['is_user'] = this.isUser;
    data['created_at'] = this.createdAt;
    return data;
  }
}

class Pagination {
  int? page;
  int? pageSize;
  bool? hasMore;

  Pagination({this.page, this.pageSize, this.hasMore});

  Pagination.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    pageSize = json['page_size'];
    hasMore = json['has_more'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page'] = this.page;
    data['page_size'] = this.pageSize;
    data['has_more'] = this.hasMore;
    return data;
  }
}
