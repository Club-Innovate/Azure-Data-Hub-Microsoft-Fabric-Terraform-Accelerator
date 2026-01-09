resource "azurerm_network_security_group" "data_nsg" {
  name                = "${var.prefix}-${var.environment}-data-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "data_subnet_assoc" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}
