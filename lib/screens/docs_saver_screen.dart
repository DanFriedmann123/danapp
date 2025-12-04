import 'package:flutter/material.dart';
import '../config/brain_theme.dart';

class DocsSaverScreen extends StatefulWidget {
  const DocsSaverScreen({super.key});

  @override
  State<DocsSaverScreen> createState() => _DocsSaverScreenState();
}

class _DocsSaverScreenState extends State<DocsSaverScreen> {
  final List<DocumentItem> _documents = [];
  final List<FolderItem> _folders = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _folderNameController = TextEditingController();
  String? _selectedFolder;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  void _addDocument() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _documents.add(
          DocumentItem(
            name: _nameController.text,
            description: _descriptionController.text,
            folder: _selectedFolder,
            dateAdded: DateTime.now(),
          ),
        );
      });

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _selectedFolder = null;

      Navigator.pop(context);
    }
  }

  void _addFolder() {
    if (_folderNameController.text.isNotEmpty) {
      setState(() {
        _folders.add(
          FolderItem(
            name: _folderNameController.text,
            dateCreated: DateTime.now(),
          ),
        );
      });

      _folderNameController.clear();
      Navigator.pop(context);
    }
  }

  void _deleteDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  void _deleteFolder(int index) {
    final folderName = _folders[index].name;
    setState(() {
      _folders.removeAt(index);
      // Remove documents in this folder
      _documents.removeWhere((doc) => doc.folder == folderName);
    });
  }

  List<DocumentItem> _getDocumentsInFolder(String? folderName) {
    return _documents.where((doc) => doc.folder == folderName).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Docs Saver', style: BrainTheme.headingSmall),
          backgroundColor: BrainTheme.primaryColor.withValues(alpha: 0.1),
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: TabBar(
            tabs: [Tab(text: 'Documents'), Tab(text: 'Folders')],
            labelColor: BrainTheme.primaryColor,
            unselectedLabelColor: BrainTheme.textSecondary,
            indicatorColor: BrainTheme.primaryColor,
          ),
        ),
        body: TabBarView(children: [_buildDocumentsTab(), _buildFoldersTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          backgroundColor: BrainTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: BrainTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Documents & Manuals', style: BrainTheme.headingMedium),
          SizedBox(height: BrainTheme.spacingS),
          Text(
            'Store and organize your important documents',
            style: BrainTheme.bodyLarge,
          ),
          SizedBox(height: BrainTheme.spacingL),
          Expanded(
            child:
                _documents.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: BrainTheme.textTertiary,
                          ),
                          SizedBox(height: BrainTheme.spacingM),
                          Text(
                            'No documents yet',
                            style: BrainTheme.headingSmall,
                          ),
                          SizedBox(height: BrainTheme.spacingS),
                          Text(
                            'Tap the + button to add your first document',
                            style: BrainTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: BrainTheme.spacingS),
                          decoration: BrainTheme.cardDecoration,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: BrainTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.description,
                                color: BrainTheme.primaryColor,
                              ),
                            ),
                            title: Text(doc.name, style: BrainTheme.bodyMedium),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (doc.description.isNotEmpty)
                                  Text(
                                    doc.description,
                                    style: BrainTheme.bodySmall,
                                  ),
                                if (doc.folder != null)
                                  Text(
                                    'Folder: ${doc.folder}',
                                    style: BrainTheme.bodySmall.copyWith(
                                      color: BrainTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  'Added: ${_formatDate(doc.dateAdded)}',
                                  style: BrainTheme.bodySmall.copyWith(
                                    color: BrainTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: BrainTheme.dangerColor,
                              ),
                              onPressed: () => _deleteDocument(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersTab() {
    return Padding(
      padding: BrainTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Folders', style: BrainTheme.headingMedium),
          SizedBox(height: BrainTheme.spacingS),
          Text(
            'Organize your documents into folders',
            style: BrainTheme.bodyLarge,
          ),
          SizedBox(height: BrainTheme.spacingL),
          Expanded(
            child:
                _folders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            size: 64,
                            color: BrainTheme.textTertiary,
                          ),
                          SizedBox(height: BrainTheme.spacingM),
                          Text(
                            'No folders yet',
                            style: BrainTheme.headingSmall,
                          ),
                          SizedBox(height: BrainTheme.spacingS),
                          Text(
                            'Create folders to organize your documents',
                            style: BrainTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        final docsInFolder = _getDocumentsInFolder(folder.name);
                        return Container(
                          margin: EdgeInsets.only(bottom: BrainTheme.spacingS),
                          decoration: BrainTheme.cardDecoration,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: BrainTheme.secondaryColor
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.folder,
                                color: BrainTheme.secondaryColor,
                              ),
                            ),
                            title: Text(
                              folder.name,
                              style: BrainTheme.bodyMedium,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${docsInFolder.length} documents',
                                  style: BrainTheme.bodySmall,
                                ),
                                Text(
                                  'Created: ${_formatDate(folder.dateCreated)}',
                                  style: BrainTheme.bodySmall.copyWith(
                                    color: BrainTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: BrainTheme.primaryColor,
                                  ),
                                  onPressed:
                                      () => _showFolderContents(folder.name),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: BrainTheme.dangerColor,
                                  ),
                                  onPressed: () => _deleteFolder(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New', style: BrainTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.description,
                    color: BrainTheme.primaryColor,
                  ),
                  title: Text('Add Document', style: BrainTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddDocumentDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.folder, color: BrainTheme.secondaryColor),
                  title: Text('Create Folder', style: BrainTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddFolderDialog(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: BrainTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Document', style: BrainTheme.headingSmall),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Document Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter document name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: BrainTheme.spacingM),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Description (Optional)',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: BrainTheme.spacingM),
                    DropdownButtonFormField<String>(
                      value: _selectedFolder,
                      decoration: BrainTheme.inputDecoration.copyWith(
                        labelText: 'Folder (Optional)',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'No Folder',
                            style: BrainTheme.bodyMedium,
                          ),
                        ),
                        ..._folders.map(
                          (folder) => DropdownMenuItem(
                            value: folder.name,
                            child: Text(
                              folder.name,
                              style: BrainTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFolder = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: BrainTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addDocument,
                style: BrainTheme.primaryButtonStyle,
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Create Folder', style: BrainTheme.headingSmall),
            content: TextField(
              controller: _folderNameController,
              decoration: BrainTheme.inputDecoration.copyWith(
                labelText: 'Folder Name',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: BrainTheme.textButtonStyle,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addFolder,
                style: BrainTheme.primaryButtonStyle,
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  void _showFolderContents(String folderName) {
    final docsInFolder = _getDocumentsInFolder(folderName);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Folder: $folderName', style: BrainTheme.headingSmall),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  docsInFolder.isEmpty
                      ? Text(
                        'No documents in this folder',
                        style: BrainTheme.bodyMedium,
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: docsInFolder.length,
                        itemBuilder: (context, index) {
                          final doc = docsInFolder[index];
                          return ListTile(
                            leading: Icon(
                              Icons.description,
                              color: BrainTheme.primaryColor,
                            ),
                            title: Text(doc.name, style: BrainTheme.bodyMedium),
                            subtitle:
                                doc.description.isNotEmpty
                                    ? Text(
                                      doc.description,
                                      style: BrainTheme.bodySmall,
                                    )
                                    : null,
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: BrainTheme.textButtonStyle,
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class DocumentItem {
  final String name;
  final String description;
  final String? folder;
  final DateTime dateAdded;

  DocumentItem({
    required this.name,
    required this.description,
    this.folder,
    required this.dateAdded,
  });
}

class FolderItem {
  final String name;
  final DateTime dateCreated;

  FolderItem({required this.name, required this.dateCreated});
}
