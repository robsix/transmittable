/**
 * author: Daniel Robinson http://github.com/0xor1
 */

part of Transmittable;

class DuplicateTranNamespaceError{
  String get message => 'Namespace "$namespace" has already been registered.';
  final String namespace;
  final String namespaceFull;
  final Map<String, String> registeredNamespaces = _namespaces;
  DuplicateTranNamespaceError(String this.namespace, String this.namespaceFull);
}