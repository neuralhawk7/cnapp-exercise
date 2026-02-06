removed {
  from = aws_subnet.public

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_route_table.public

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_route_table_association.public_assoc

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_route.public_internet

  lifecycle {
    destroy = false
  }
}
