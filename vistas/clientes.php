<div class="content-header">
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-6">
                <h2 class="m-0">Clientes</h2>
            </div>
            <div class="col-md-6">
                <ol class="breadcrumb float-md-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item active">Clientes</li>
                </ol>
            </div>
        </div>
    </div>
</div>

<div class="content pb-2">
    <div class="row p-0 m-0">

        <!--LISTADO DE CATEGORIAS -->
        <div class="col-md-8">
            <div class="card card-gray shadow">
                <div class="card-header">
                    <h3 class="card-title"><i class="fas fa-list"></i> Listado de Clientes</h3>
                </div>
                <div class="card-body">
                    <table id="lstClientes" class="table table-striped w-100 shadow border border-secondary">
                        <thead class="bg-gray text-left">
                            <th>id</th>
                            <th>Nombres</th>
                            <th>Apellidos</th>
                            <th>Telefono</th>
                            <th>direccion</th>
                            <th class="text-center">Opciones</th>
                        </thead>
                        <tbody class="small text left">

                        </tbody>
                    </table>
                </div>
            </div>
        </div>

         <!--FORMULARIO PARA REGISTRO Y EDICION -->
        <div class="col-md-4">
            <div class="card card-gray shadow">
                <div class="card-header">
                    <h3 class="card-title"><i class="fas fa-edit"></i> Registro de Clientes</h3>
                </div>
                <div class="card-body">

                    <form class="needs-validation" novalidate>

                        <div class="row">

                            <div class="col-md-12">

                                <div class="form-group mb-2">
                                    
                                    <label  class="col-form-label" for="iptNombres">
                                        <i class="fas fa-dumpster fs-6"></i>
                                        <span class="small">Nombres</span><span class="text-danger">*</span>
                                    </label>
                                    
                                    <input type="text" class="form-control form-control-sm" id="iptNombres"
                                        name="iptNombres" placeholder="Ingrese los Nombres" required>
                                    
                                    <div class="invalid-feedback">Debe ingresar los nombres</div>

                                </div>

                            </div>
                             <div class="col-md-12">

                                <div class="form-group mb-2">
                                    
                                    <label  class="col-form-label" for="iptApellidos">
                                        <i class="fas fa-dumpster fs-6"></i>
                                        <span class="small">Apellidos</span><span class="text-danger">*</span>
                                    </label>
                                    
                                    <input type="text" class="form-control form-control-sm" id="iptApellidos"
                                        name="iptApellidos" placeholder="Ingrese los Apellidos" required>
                                    
                                    <div class="invalid-feedback">Debe ingresar los apellidos</div>

                                </div>

                            </div>
                             <div class="col-md-12">

                                <div class="form-group mb-2">
                                    
                                    <label  class="col-form-label" for="iptTelefono">
                                        <i class="fas fa-dumpster fs-6"></i>
                                        <span class="small">Telefono</span><span class="text-danger">*</span>
                                    </label>
                                    
                                    <input type="text" class="form-control form-control-sm" id="iptTelefono"
                                        name="iptTelefono" placeholder="Ingrese el Telefono" required>
                                    
                                    <div class="invalid-feedback">Debe ingresar el telefono</div>

                                </div>

                            </div>
                             <div class="col-md-12">

                                <div class="form-group mb-2">
                                    
                                    <label  class="col-form-label" for="iptDireccion">
                                        <i class="fas fa-dumpster fs-6"></i>
                                        <span class="small">Direccion</span><span class="text-danger">*</span>
                                    </label>
                                    
                                    <input type="text" class="form-control form-control-sm" id="iptDireccion"
                                        name="iptDireccion" placeholder="Ingrese la Direccion" required>
                                    
                                    <div class="invalid-feedback">Debe ingresar la direccion</div>

                                </div>

                            </div>

                            <div class="col-md-12">
                                <div class="form-group m-0 mt-2">
                                    <a style="cursor:pointer;"
                                        class="btn btn-primary btn-sm w-100"
                                        id="btnRegistrarCliente">Registrar Cliente
                                    </a>
                                </div>
                            </div>
                        </div>
                    </form>  
                </div>
            </div>
        </div>
    </div>
</div>

<script>

    var Toast = Swal.mixin({
            toast: true,
            position: 'top',
            showConfirmButton: false,
            timer: 3000
        });


    $(document).ready(function(){

        //variables para registrar o editar un cliente
            var id = 0;        
            var nombres = "";
            var apellidos = "";
            var telefono = "";
            var direccion = "";
        
        var tableClientes = $('#lstClientes').DataTable({
            dom: 'Bfrtip',
                buttons: [
                    'excel', 'print', 'pageLength',
                ],
                ajax: {
                    url: 'ajax/clientes.ajax.php',
                    dataSrc: ""
                },
                columnDefs: [
                    {
                        targets: 5,
                        sortable: false,
                        render: function(data, type, full, meta) {
                            return "<center>" +
                                        "<span class='btnEditarCliente text-primary px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Editar Cliente'> " +
                                        "<i class='fas fa-pencil-alt fs-5'></i> " +
                                        "</span> " +
                                        "<span class='btnEliminarCliente text-danger px-1'style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Eliminar Cliente'> " +
                                        "<i class='fas fa-trash fs-5'> </i> " +
                                        "</span>" +
                                "</center>";
                        }
                    }
                ],
                "order": [[ 0, 'desc' ]],
                lengthMenu: [0, 5, 10, 15, 20, 50],
                "pageLength": 10,
                "language": {
                    "url": "//cdn.datatables.net/plug-ins/1.10.20/i18n/Spanish.json"
                }
        });

        $('#lstClientes tbody').on('click', '.btnEditarCliente', function() {

                var data = tableClientes.row($(this).parents('tr')).data();

                if ($(this).parents('tr').hasClass('selected')) {

                    $(this).parents('tr').removeClass('selected');

                    id = 0;
                    $("#iptNombres").val("");
                    $("#iptApellidos").val("");
                    $("#iptTelefono").val("");
                    $("#iptDireccion").val("");

                }else{

                    tableClientes.$('tr.selected').removeClass('selected');                    
                    $(this).parents('tr').addClass('selected'); 

                    id = data[0];
                    $("#iptNombres").val(data[1]);
                    $("#iptApellidos").val(data[2]);
                    $("#iptTelefono").val(data[3]);
                    $("#iptDireccion").val(data[4]);

                    
                }
            })

            $('#lstClientes tbody').on('click', '.btnEliminarCliente', function() {

                var data = tableClientes.row($(this).parents('tr')).data();

                Swal.fire({
                    title: 'Está seguro de eliminar al cliente ' + data[1] +'?',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Aceptar!',
                    cancelButtonText: 'Cancelar!',
                }).then((result) => {
                    if (result.isConfirmed) {

                        
                        
                    }
                })
            })

            document.getElementById("btnRegistrarCliente").addEventListener("click", function() {

                // Get the forms we want to add validation styles to
                var forms = document.getElementsByClassName('needs-validation');

                // Loop over them and prevent submission
                var validation = Array.prototype.filter.call(forms, function(form) {

                    if (form.checkValidity() === true) { 
                        
                        nombres = $("#iptNombres").val();
                        apellidos = $("#iptApellidos").val();
                        telefono = $("#iptTelefono").val();
                        direccion = $("#iptDireccion").val();

                        var datos = new FormData();

                        datos.append("id",id);
                        datos.append("nombres",nombres);
                        datos.append("apellidos",apellidos);
                        datos.append("telefono",telefono);
                        datos.append("direccion",direccion);
                        
                        Swal.fire({
                            title: 'Está seguro de guardar al cliente?',
                            icon: 'warning',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            cancelButtonColor: '#d33',
                            confirmButtonText: 'Aceptar!',
                            cancelButtonText: 'Cancelar!',
                        }).then((result) => {

                            if (result.isConfirmed) {
                                
                                $.ajax({
                                    url: "ajax/clientes.ajax.php",
                                    type: "POST",
                                    data: datos,
                                    cache: false,
                                    contentType: false,
                                    processData: false,
                                    dataType: 'json',
                                    success:function(respuesta){

                                        Toast.fire({
                                            icon: 'success',
                                            title: respuesta
                                        });
                                        
                                        id = 0;
                                        nombres = "";
                                        apellidos = "";
                                        telefono = "";
                                        direccion = "";

                                        $("#iptNombres").val("");
                                        $("#iptApellidos").val("");
                                        $("#iptTelefono").val("");
                                        $("#iptDireccion").val("");

                                        tableClientes.ajax.reload();
                                        $(".needs-validation").removeClass("was-validated");
                                    }
                                });
                            }
                        })
                    }

                    form.classList.add('was-validated');

                })
                
            });
    })
    </script>