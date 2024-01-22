resource "keycloak_authentication_flow" "smart_flow" {
  realm_id    = data.keycloak_realm.realm.id
  alias       = "smart browser"
  description = "SMART App Launch Support Authentication"
}

resource "keycloak_authentication_subflow" "smart_subflow" {
  realm_id          = data.keycloak_realm.realm.id
  alias             = "smart-launch-subflow"
  description       = "SMART Launch Flow"
  parent_flow_alias = keycloak_authentication_flow.smart_flow.alias
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
}

// This is the custom authenticator that is in the jar file created.
resource "keycloak_authentication_execution" "execution_1" {
  realm_id          = data.keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.smart_subflow.alias
  authenticator     = "smart-ehr-launch"
  requirement       = "ALTERNATIVE"
  depends_on        = [keycloak_authentication_execution.execution_1]
}

// Example of how to configure the custom authenticator for SMART EHR-Launch
// resolving of context via call to context API.
resource "keycloak_authentication_execution_config" "execution_1_config" {
  realm_id     = data.keycloak_realm.realm.id
  execution_id = keycloak_authentication_execution.execution_1.id
  alias        = "smart-ehr-launch-config"
  config = {
    context-api-url       = var.keycloak_smart_configuration.context_url
    context-token-url     = var.keycloak_smart_configuration.context_token_url
    context-client-id     = var.keycloak_smart_configuration.context_client_id
    context-client-secret = var.keycloak_smart_configuration.context_client_secret
    context-client-scopes = "context:read"
    standalone-scopes     = var.keycloak_smart_configuration.standalone_scopes
  }
}

resource "keycloak_authentication_execution" "execution_2" {
  realm_id          = data.keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.smart_subflow.alias
  authenticator     = "smart-audience-validator"
  requirement       = "ALTERNATIVE"
}
resource "keycloak_authentication_execution_config" "execution_2_config" {
  realm_id     = data.keycloak_realm.realm.id
  execution_id = keycloak_authentication_execution.execution_2.id
  alias        = "smart-audience-validator-config"
  config = {
    smart-audiences = var.keycloak_smart_configuration.audiences
  }
}

resource "keycloak_authentication_execution" "execution_3" {
  realm_id          = data.keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.smart_flow.alias
  authenticator     = "auth-cookie"
  requirement       = "DISABLED" // for testing only. Set to ALTERNATVIE otherwise
  depends_on        = [keycloak_authentication_execution.execution_2]
}

resource "keycloak_authentication_execution" "execution_4" {
  realm_id          = data.keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.smart_flow.alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  depends_on        = [keycloak_authentication_execution.execution_3]
}

resource "keycloak_authentication_subflow" "subflow" {
  realm_id          = data.keycloak_realm.realm.id
  alias             = "user-login-form"
  description       = "Username, password, otp and other auth forms."
  parent_flow_alias = keycloak_authentication_flow.smart_flow.alias
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
  depends_on = [ keycloak_authentication_execution.execution_4 ]
}

resource "keycloak_authentication_execution" "execution_5" {
  realm_id          = data.keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.subflow.alias
  authenticator     = "auth-username-password-form"
  requirement       = "REQUIRED"
}

// BIND THIS FLOW TO THE REALM-LEVEL BROWSER FLOW
/*
resource "keycloak_authentication_bindings" "browser_authentication_binding" {
  realm_id     = keycloak_authentication_flow.smart_flow.realm_id
  browser_flow = keycloak_authentication_flow.smart_flow.alias
} */

