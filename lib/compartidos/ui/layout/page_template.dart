import 'package:flutter/material.dart';

class PageTemplate extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final bool centerTitle;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomSheet;

  const PageTemplate({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.centerTitle = true,
    this.appBar,
    this.backgroundColor,
    this.padding,
    this.resizeToAvoidBottomInset = true,
    this.bottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: showAppBar ? (appBar ?? _buildDefaultAppBar(context)) : null,
      body: padding != null ? Padding(padding: padding!, child: body) : body,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomSheet: bottomSheet,
    );
  }

  PreferredSizeWidget? _buildDefaultAppBar(BuildContext context) {
    if (title == null && actions == null) return null;

    return AppBar(
      title: title != null ? Text(title!) : null,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 1,
    );
  }
}

class FormPageTemplate extends StatelessWidget {
  final String title;
  final Widget form;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final EdgeInsetsGeometry? padding;

  const FormPageTemplate({
    super.key,
    required this.title,
    required this.form,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: title,
      showAppBar: showAppBar,
      actions: actions,
      floatingActionButton: floatingActionButton,
      padding: padding ?? const EdgeInsets.all(16),
      body: SingleChildScrollView(
        child: form,
      ),
    );
  }
}

class ListPageTemplate extends StatelessWidget {
  final String title;
  final Widget list;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? searchBar;
  final Widget? filterBar;
  final bool showAppBar;

  const ListPageTemplate({
    super.key,
    required this.title,
    required this.list,
    this.floatingActionButton,
    this.actions,
    this.searchBar,
    this.filterBar,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: title,
      showAppBar: showAppBar,
      actions: actions,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          if (searchBar != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: searchBar!,
            ),
          ],
          if (filterBar != null) ...[
            filterBar!,
            const Divider(height: 1),
          ],
          Expanded(child: list),
        ],
      ),
    );
  }
}