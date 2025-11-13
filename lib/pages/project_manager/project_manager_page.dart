import 'package:flutter/material.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/project.dart';
import 'package:kivixa/data/project_storage.dart';

class ProjectManagerPage extends StatefulWidget {
  const ProjectManagerPage({super.key});

  @override
  State<ProjectManagerPage> createState() => _ProjectManagerPageState();
}

class _ProjectManagerPageState extends State<ProjectManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Project> _allProjects = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await ProjectStorage.loadProjects();
    setState(() {
      _allProjects = projects;
      _isLoading = false;
    });
  }

  List<Project> get _upcomingProjects =>
      _allProjects.where((p) => p.status == ProjectStatus.upcoming).toList();

  List<Project> get _ongoingProjects =>
      _allProjects.where((p) => p.status == ProjectStatus.ongoing).toList();

  List<Project> get _completedProjects =>
      _allProjects.where((p) => p.status == ProjectStatus.completed).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.folder)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'Ongoing', icon: Icon(Icons.work)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProjectList(_allProjects),
                _buildProjectList(_upcomingProjects),
                _buildProjectList(_ongoingProjects),
                _buildProjectList(_completedProjects),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildProjectList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No projects yet', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectColor = project.color ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: projectColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (project.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            project.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(project.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.task_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${project.taskIds.length} tasks',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${project.changes.length} changes',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showProjectMenu(project),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ProjectStatus.upcoming:
        color = Colors.blue;
        icon = Icons.schedule;
        label = 'Upcoming';
      case ProjectStatus.ongoing:
        color = Colors.orange;
        icon = Icons.work;
        label = 'Ongoing';
      case ProjectStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Completed';
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showProjectMenu(Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Project'),
            onTap: () {
              Navigator.pop(context);
              _showEditProjectDialog(project);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Project'),
            onTap: () {
              Navigator.pop(context);
              _deleteProject(project.id);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog() {
    _showProjectDialog(null);
  }

  void _showEditProjectDialog(Project project) {
    _showProjectDialog(project);
  }

  void _showProjectDialog(Project? project) {
    final titleController = TextEditingController(text: project?.title ?? '');
    final descriptionController = TextEditingController(
      text: project?.description ?? '',
    );
    ProjectStatus selectedStatus = project?.status ?? ProjectStatus.upcoming;
    Color? selectedColor = project?.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(project == null ? 'Create Project' : 'Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name[0].toUpperCase() + status.name.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Project Color'),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          selectedColor ??
                          Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  onTap: () async {
                    final color = await _showColorPicker(selectedColor);
                    if (color != null) {
                      setState(() => selectedColor = color);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                final newProject = Project(
                  id:
                      project?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  status: selectedStatus,
                  changes: project?.changes ?? [],
                  taskIds: project?.taskIds ?? [],
                  createdAt: project?.createdAt ?? DateTime.now(),
                  completedAt: selectedStatus == ProjectStatus.completed
                      ? DateTime.now()
                      : null,
                  color: selectedColor,
                );

                if (project == null) {
                  ProjectStorage.addProject(newProject);
                } else {
                  ProjectStorage.updateProject(newProject);
                }

                _loadProjects();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _showColorPicker(Color? currentColor) async {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = currentColor == color;
            return InkWell(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ProjectStorage.deleteProject(projectId);
      _loadProjects();
    }
  }

  void _showProjectDetails(Project project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(project: project),
      ),
    );
    _loadProjects();
  }
}

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({required this.project, super.key});

  final Project project;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Project _project;
  List<CalendarEvent> _tasks = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 3, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    final allTasks = await CalendarStorage.loadEvents();
    final projectTasks = allTasks
        .where((task) => _project.taskIds.contains(task.id))
        .toList();

    // Reload project to get latest changes
    final updatedProject = await ProjectStorage.getProjectById(_project.id);

    setState(() {
      _tasks = projectTasks;
      if (updatedProject != null) {
        _project = updatedProject;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProject(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tasks'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTasksTab(),
                _buildTimelineTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddChangeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Change'),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_project.description != null) ...[
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_project.description!),
            const SizedBox(height: 24),
          ],
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _project.status.name[0].toUpperCase() +
                _project.status.name.substring(1),
          ),
          const SizedBox(height: 24),
          Text('Changes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Completed: ${_project.completedChanges.length}'),
          Text('Pending: ${_project.pendingChanges.length}'),
          const SizedBox(height: 16),
          if (_project.pendingChanges.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Pending Changes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._project.pendingChanges.map(
              (change) => _buildChangeItem(change),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeItem(ProjectChange change) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: change.isCompleted,
          onChanged: (value) => _toggleChangeStatus(change),
        ),
        title: Text(
          change.description,
          style: TextStyle(
            decoration: change.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _formatDateTime(change.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => _deleteChange(change),
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks linked to this project',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              task.type == EventType.task ? Icons.task_alt : Icons.event,
            ),
            title: Text(task.title),
            subtitle: Text(
              '${task.date.year}-${task.date.month.toString().padLeft(2, '0')}-${task.date.day.toString().padLeft(2, '0')}',
            ),
            trailing: task.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () => _showTaskDetails(task),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    final timeline = _project.timeline;

    if (timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No changes recorded yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final change = timeline[index];
        return _buildTimelineItem(change, index == timeline.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(ProjectChange change, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: change.isCompleted ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    change.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(change.timestamp),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChangeDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Change'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final change = ProjectChange(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: controller.text.trim(),
                  timestamp: DateTime.now(),
                );
                await ProjectStorage.addChangeToProject(_project.id, change);
                _loadProjectData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleChangeStatus(ProjectChange change) async {
    final updated = change.copyWith(isCompleted: !change.isCompleted);
    await ProjectStorage.updateChangeInProject(_project.id, updated);
    _loadProjectData();
  }

  Future<void> _deleteChange(ProjectChange change) async {
    final changes = [..._project.changes]
      ..removeWhere((c) => c.id == change.id);
    await ProjectStorage.updateProject(_project.copyWith(changes: changes));
    _loadProjectData();
  }

  void _editProject() {
    // Navigate back and refresh parent
    Navigator.pop(context);
  }

  void _showTaskDetails(CalendarEvent task) {
    // Show task details dialog (to be implemented)
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
