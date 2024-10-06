<?php

require_once "conexion.php";

class ClientesModelo{


    static public function mdlListarClientes(){

        $stmt = Conexion::conectar()->prepare("SELECT  id, 
                                                        nombres, 
                                                        apellidos, 
                                                        telefono,
                                                        direccion, 
                                                        '' as opciones
                                                FROM clientes c order BY id DESC");

        $stmt -> execute();

        return $stmt->fetchAll();
    }

    static public function mdlGuardarCliente($accion, $id, $nombres, $apellidos, $telefono, $direccion){

        $date = null;

        if($accion > 0){// REGISTRAR

            
            $stmt = Conexion::conectar()->prepare("INSERT INTO clientes(nombres,apellidos,telefono, direccion) 
            VALUES(:nombres,:apellidos,:telefono, :direccion)");

            $stmt -> bindParam(":nombres", $nombres , PDO::PARAM_STR);
            $stmt -> bindParam(":apellidos", $apellidos , PDO::PARAM_STR);
            $stmt -> bindParam(":telefono",  $telefono , PDO::PARAM_STR);
            $stmt -> bindParam(":direccion",  $direccion , PDO::PARAM_STR);

            if($stmt -> execute()){
                $resultado = "Se registró el cliente correctamente.";
            }else{
                $resultado = "Error al registrar el cliente";
            }

        }else{// EDITAR


            $stmt = Conexion::conectar()->prepare("UPDATE clientes 
                                                      SET nombres = :nombres,
                                                          apellidos = :apellidos,
                                                          telefono = :telefono,
                                                          direccion = :direccion
                                                    WHERE id = :id") ;
            

            $stmt -> bindParam(":id", $id , PDO::PARAM_STR);
            $stmt -> bindParam(":nombres", $nombres , PDO::PARAM_STR);
            $stmt -> bindParam(":apellidos", $apellidos, PDO::PARAM_STR);
            $stmt -> bindParam(":telefono", $telefono , PDO::PARAM_STR);
            $stmt -> bindParam(":direccion", $direccion, PDO::PARAM_STR);

            if($stmt -> execute()){
                $resultado = "Se actualizó al cliente correctamente.";
            }else{
                $resultado = "Error al actualizar al cliente";
            }
        }

        return $resultado;
        
        $stmt = null;

    }

}

