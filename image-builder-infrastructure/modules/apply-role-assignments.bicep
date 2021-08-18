param assignments array = []

resource principalRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for (assignment, i) in assignments: {
  name: guid(resourceGroup().id, assignment.roleDefinitionId, assignment.principalId) // reproducable GUID
  properties: {
    roleDefinitionId: assignment.roleDefinitionId
    principalId: assignment.principalId
  }
}]
