import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/project.dart';
import 'package:kivixa/data/project_storage.dart';

/// Generates a random unique color for projects using HSL for vibrant colors
Color generateRandomProjectColor() {
  final random = Random();
  // Generate vibrant colors by using HSL with high saturation
  final hue = random.nextDouble() * 360;
  final saturation = 0.6 + random.nextDouble() * 0.3; // 60-90%
  final lightness = 0.4 + random.nextDouble() * 0.2; // 40-60%
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

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
  var _searchQuery = '';
  var _sortBy = 'lastActivity'; // 'lastActivity', 'name', 'created'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  List<Project> get _filteredProjects {
    var filtered = _allProjects.where((p) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.title.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    // Sort projects
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
      case 'created':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'lastActivity':
      default:
        filtered.sort((a, b) {
          final aTime = a.lastActivityAt ?? a.createdAt;
          final bTime = b.lastActivityAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
    }

    return filtered;
  }

  List<Project> get _upcomingProjects => _filteredProjects
      .where((p) => p.status == ProjectStatus.upcoming)
      .toList();

  List<Project> get _ongoingProjects => _filteredProjects
      .where((p) => p.status == ProjectStatus.ongoing)
      .toList();

  List<Project> get _completedProjects => _filteredProjects
      .where((p) => p.status == ProjectStatus.completed)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Find a project...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _buildStatChip(
                      Icons.folder,
                      '${_allProjects.length}',
                      'Total',
                      colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.play_circle,
                      '${_allProjects.where((p) => p.status == ProjectStatus.ongoing).length}',
                      'Active',
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.check_circle,
                      '${_allProjects.where((p) => p.status == ProjectStatus.completed).length}',
                      'Done',
                      Colors.green,
                    ),
                    const Spacer(),
                    // Sort dropdown
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort by',
                      onSelected: (value) => setState(() => _sortBy = value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'lastActivity',
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: _sortBy == 'lastActivity'
                                    ? colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Last activity'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort_by_alpha,
                                color: _sortBy == 'name'
                                    ? colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Name'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'created',
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _sortBy == 'created'
                                    ? colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Date created'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All', icon: Icon(Icons.folder)),
                  Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
                  Tab(text: 'Active', icon: Icon(Icons.play_circle)),
                  Tab(text: 'Done', icon: Icon(Icons.check_circle)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProjectList(_filteredProjects),
                _buildProjectList(_upcomingProjects),
                _buildProjectList(_ongoingProjects),
                _buildProjectList(_completedProjects),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No projects match "$_searchQuery"'
                  : 'No projects yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create your first project to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showCreateProjectDialog(),
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
            ],
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
    final lastActivity = project.lastActivityAt ?? project.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color bar at top (GitHub-style repo indicator)
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [projectColor, projectColor.withValues(alpha: 0.5)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with status badge
                  Row(
                    children: [
                      Icon(Icons.folder, color: projectColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      _buildStatusChip(project.status),
                    ],
                  ),
                  // Description
                  if (project.description != null &&
                      project.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      project.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Stats row (GitHub-style)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildProjectStat(
                        Icons.description,
                        '${project.noteIds.length} notes',
                      ),
                      _buildProjectStat(
                        Icons.task_alt,
                        '${project.taskIds.length} tasks',
                      ),
                      _buildProjectStat(
                        Icons.commit,
                        '${project.changes.length} commits',
                      ),
                      _buildProjectStat(
                        Icons.access_time,
                        _formatRelativeTime(lastActivity),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action bar
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditProjectDialog(project),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showProjectMenu(project),
                    icon: const Icon(Icons.more_horiz, size: 18),
                    label: const Text('More'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
        icon = Icons.play_circle_outline;
        label = 'Active';
      case ProjectStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'Done';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectMenu(Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
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
              leading: const Icon(Icons.note_add),
              title: const Text('Link Note'),
              onTap: () {
                Navigator.pop(context);
                _showLinkNoteDialog(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Duplicate Project'),
              onTap: () {
                Navigator.pop(context);
                _duplicateProject(project);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Project',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteProject(project.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkNoteDialog(Project project) {
    // TODO: Implement note linking dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note linking coming soon!')));
  }

  Future<void> _duplicateProject(Project project) async {
    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${project.title} (Copy)',
      description: project.description,
      status: ProjectStatus.upcoming,
      changes: [],
      taskIds: [],
      noteIds: [],
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      color: generateRandomProjectColor(),
    );

    await ProjectStorage.addProject(newProject);
    _loadProjects();
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
    // Auto-generate random color for new projects
    Color selectedColor = project?.color ?? generateRandomProjectColor();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                project == null ? Icons.create_new_folder : Icons.edit,
                color: selectedColor,
              ),
              const SizedBox(width: 8),
              Text(project == null ? 'New Project' : 'Edit Project'),
            ],
          ),
          content: ConstrainedBox(
            // Make dialog wider
            constraints: const BoxConstraints(minWidth: 500, maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Project name',
                      hintText: 'Enter a unique project name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Brief description of your project',
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
                      IconData icon;
                      Color color;
                      switch (status) {
                        case ProjectStatus.upcoming:
                          icon = Icons.schedule;
                          color = Colors.blue;
                        case ProjectStatus.ongoing:
                          icon = Icons.play_circle;
                          color = Colors.orange;
                        case ProjectStatus.completed:
                          icon = Icons.check_circle;
                          color = Colors.green;
                      }
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              status.name[0].toUpperCase() +
                                  status.name.substring(1),
                            ),
                          ],
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
                  // Color picker section
                  Text(
                    'Project Color',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final color = await _showFullColorPicker(selectedColor);
                      if (color != null) {
                        setState(() => selectedColor = color);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Click to change color'),
                              Text(
                                '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.shuffle),
                            tooltip: 'Random color',
                            onPressed: () {
                              setState(
                                () => selectedColor =
                                    generateRandomProjectColor(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project name is required')),
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
                  noteIds: project?.noteIds ?? [],
                  createdAt: project?.createdAt ?? DateTime.now(),
                  lastActivityAt: DateTime.now(),
                  completedAt: selectedStatus == ProjectStatus.completed
                      ? DateTime.now()
                      : null,
                  color: selectedColor,
                  readme: project?.readme,
                  starCount: project?.starCount ?? 0,
                );

                if (project == null) {
                  ProjectStorage.addProject(newProject);
                } else {
                  ProjectStorage.updateProject(newProject);
                }

                _loadProjects();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: Text(project == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Full color spectrum picker using flutter_colorpicker
  Future<Color?> _showFullColorPicker(Color currentColor) async {
    Color pickedColor = currentColor;

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => pickedColor = color,
            enableAlpha: false,
            hexInputBar: true,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, pickedColor),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Project'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this project? '
          'This action cannot be undone.',
        ),
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
    _tabController = TabController(length: 4, vsync: this);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectColor = _project.color ?? colorScheme.primary;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      projectColor.withValues(alpha: 0.8),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 16, 16, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.folder,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _project.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_project.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _project.description!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editProject(),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMoreOptions(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'Overview'),
                Tab(icon: Icon(Icons.description), text: 'Notes'),
                Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                Tab(icon: Icon(Icons.history), text: 'Activity'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildNotesTab(),
                  _buildTasksTab(),
                  _buildActivityTab(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Project'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Project'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Project',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Delete project and go back
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add to Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.commit, color: Colors.green),
              title: const Text('New Commit'),
              subtitle: const Text('Record a change or progress'),
              onTap: () {
                Navigator.pop(context);
                _showAddChangeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt, color: Colors.orange),
              title: const Text('New Task'),
              subtitle: const Text('Add a task to this project'),
              onTap: () {
                Navigator.pop(context);
                _showAddTaskDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Link Note'),
              subtitle: const Text('Connect an existing note'),
              onTap: () {
                Navigator.pop(context);
                _showLinkNoteDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task creation coming soon!')));
  }

  void _showLinkNoteDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note linking coming soon!')));
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final projectColor = _project.color ?? theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards (GitHub-style)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Notes',
                  '${_project.noteIds.length}',
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tasks',
                  '${_project.taskIds.length}',
                  Icons.task_alt,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Commits',
                  '${_project.changes.length}',
                  Icons.commit,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status section
          Text('Status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                _project.status == ProjectStatus.completed
                    ? Icons.check_circle
                    : _project.status == ProjectStatus.ongoing
                    ? Icons.play_circle
                    : Icons.schedule,
                color: _project.status == ProjectStatus.completed
                    ? Colors.green
                    : _project.status == ProjectStatus.ongoing
                    ? Colors.orange
                    : Colors.blue,
              ),
              title: Text(
                _project.status.name[0].toUpperCase() +
                    _project.status.name.substring(1),
              ),
              subtitle: Text('Created ${_formatDateTime(_project.createdAt)}'),
              trailing: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: projectColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent activity
          Text('Recent Activity', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_project.changes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => _showAddChangeDialog(),
                        child: const Text('Add first commit'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...(_project.timeline
                .take(5)
                .map((change) => _buildRecentActivityItem(change))),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(ProjectChange change) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: change.isCompleted ? Colors.green : Colors.orange,
          radius: 16,
          child: Icon(
            change.isCompleted ? Icons.check : Icons.commit,
            size: 16,
            color: Colors.white,
          ),
        ),
        title: Text(change.description),
        subtitle: Text(_formatRelativeTime(change.timestamp)),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          onPressed: () => _showChangeOptions(change),
        ),
      ),
    );
  }

  void _showChangeOptions(ProjectChange change) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                change.isCompleted ? Icons.undo : Icons.check_circle,
              ),
              title: Text(
                change.isCompleted ? 'Mark as pending' : 'Mark as completed',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _toggleChangeStatus(change);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteChange(change);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotesTab() {
    if (_project.noteIds.isEmpty) {
      return _buildEmptyTab(
        Icons.description,
        'No notes linked',
        'Link existing notes or create new ones for this project',
        'Link Note',
        () => _showLinkNoteDialog(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _project.noteIds.length,
      itemBuilder: (context, index) {
        final noteId = _project.noteIds[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(noteId.split('/').last),
            subtitle: Text(noteId),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                // Open note
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(
    IconData icon,
    String title,
    String subtitle,
    String buttonLabel,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
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

  Widget _buildActivityTab() {
    final timeline = _project.timeline;

    if (timeline.isEmpty) {
      return _buildEmptyTab(
        Icons.history,
        'No activity recorded',
        'Commit changes to track project progress',
        'Add Commit',
        () => _showAddChangeDialog(),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: change.isCompleted ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  change.isCompleted ? Icons.check : Icons.commit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.description,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(change.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
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
        title: const Row(
          children: [
            Icon(Icons.commit, color: Colors.green),
            SizedBox(width: 8),
            Text('New Commit'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Commit message',
            hintText: 'Describe what changed...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final change = ProjectChange(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: controller.text.trim(),
                  timestamp: DateTime.now(),
                );
                await ProjectStorage.addChangeToProject(_project.id, change);
                _loadProjectData();
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Commit'),
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
