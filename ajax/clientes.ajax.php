<?php

require_once "../controladores/clientes.controlador.php";
require_once "../modelos/clientes.modelo.php";

class AjaxClientes{

    public $id;
    public $nombres;
    public $apellidos;
    public $telefono;
    public $direccion;

    public function ajaxListarClientes(){

        $clientes = ClientesControlador::ctrListarClientes();

        echo json_encode($clientes, JSON_UNESCAPED_UNICODE);
    }

    public function ajaxGuardarCliente($accion){

        $guardarClientes = ClientesControlador::ctrGuardarCliente($accion, $this->id, $this->nombres, $this->apellidos, $this->telefono, $this->direccion);

        echo json_encode($guardarClientes, JSON_UNESCAPED_UNICODE);
    }


}

if(isset($_POST['id']) && $_POST['id'] > 0){ //EDITAR

    $editarCliente = new AjaxClientes();
    $editarCliente->id = $_POST['id'];
    $editarCliente->nombres = $_POST['nombres'];
    $editarCliente->apellidos = $_POST['apellidos'];
    $editarCliente->telefono = $_POST['telefono'];
    $editarCliente->direccion = $_POST['direccion'];
    $editarCliente->ajaxGuardarCliente(0);

}else if(isset($_POST['id']) && $_POST['id'] == 0){ //REGISTRAR

    $registrarCliente = new AjaxClientes();
    $registrarCliente->id = $_POST['id'];
    $registrarCliente->nombres = $_POST['nombres'];
    $registrarCliente->apellidos = $_POST['apellidos'];
    $registrarCliente->telefono = $_POST['telefono'];
    $registrarCliente->direccion = $_POST['direccion'];
    $registrarCliente->ajaxGuardarCliente(1);

}else{
    $listaClientes = new AjaxClientes();
    $listaClientes -> ajaxListarClientes();
}


    