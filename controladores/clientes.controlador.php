<?php

class ClientesControlador{

    static public function ctrListarClientes(){
        
        $clientes = ClientesModelo::mdlListarClientes();

        return $clientes;
  
    }

    static public function ctrGuardarCliente($accion, $id, $nombres, $apellidos, $telefono, $direccion){

        $guardarCliente = ClientesModelo::mdlGuardarCliente($accion, $id, $nombres, $apellidos, $telefono, $direccion);

        return $guardarCliente;
    }


}