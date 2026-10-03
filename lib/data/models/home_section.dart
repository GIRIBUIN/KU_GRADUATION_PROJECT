enum HomeSection {
  todayTasks('todayTasks', '오늘 할 일'),
  urgentTasks('urgentTasks', '마감 임박'),
  selectedTagTasks('selectedTagTasks', '선택 태그'),
  overdueTasks('overdueTasks', '마감 지남'),
  calendar('calendar', '캘린더');

  const HomeSection(this.id, this.label);

  final String id;
  final String label;

  static const defaultHidden = {HomeSection.calendar};

  static HomeSection? fromId(String id) {
    return values.where((section) => section.id == id).firstOrNull;
  }
}
