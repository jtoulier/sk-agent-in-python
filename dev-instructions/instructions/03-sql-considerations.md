# Consideraciones Técnicas Generales
Vas a generar una serie de archivos SQL compatible con Azure SQL, no interesan los demás motores de Base de Datos siempre y cuando cumplan con los criterios establecidos a lo largo de este documento.

Todos los objetos serán en minúsculas y separados con el caracter "_".

Las sentencias culmínalas con ";".

En lo posible te daré los nombres de los objetos y debes respetarlos, en caso no te los de, debes agregarlos tú y deben estar en inglés.

Antes de un CREATE SCHEMA o CREATE TRIGGER, pon una sentencia GO para separar los bloques y no ocasione un error en su ejecución, obviamente si es la primera sentencia del archivo, no pongas el GO.

Todas las fechas y horas deben considerarse en la zona horaria -5 de Lima, Perú.

Todos los campos de las tablas son obligatorios, a no ser que se indique lo contrario.

Si indico un FOREIGN KEY, toma el tipo de dato de la tabla padre.

## Consideraciones para las Tablas
Las tablas tienen un nombre y pertenecen a un esquema. Las tablas deben tener el nombre en plural.

Asimismo, para efectos de nomenclatura, tienen definido un nemónico, cuyo uso se explica más adelante.

Finalmente tienen un atributo booleano "Trazabilidad", cuyo uso también explico más adelante. Si no indico un valor para Trazabilidad, interpreta que no debe tener Trazabilidad.

## Consideraciones para los Primary Keys
Los Primary Key (PK) deben tener el formato:

pk_{nemonico}

donde:

{nemonico} es el nemónico de la tabla

## Consideraciones para los Foreign Keys
Los Foreign Key (FK) deben tener el formato:

fk_{nemonico_tabla_padre}_{nemonico_tabla_hija}

donde:

{nemonico_tabla_padre} es el nemónico de la tabla padre


{nemonico_tabla_hija} es el nemónico de la tabla hija, la que recibe el FK

## Consideraciones para las Tablas de Trazabilidad
Si la tabla tiene la indicación "Trazabilidad = Sí"

a) Generar una tabla adicional, en el mismo esquema de la tabla, con el formato "{tabla}_atl" donde:
{tabla} es el nombre de la tabla y sus campos son:

| Campo          | Tipo de Datos     | Explicación                                                  |
| -------------- | ----------------- | ------------------------------------------------------------ |
| atl_written_at | DATETIMEOFFSET(2) | es la fecha y hora en que se dispara el trigger              |
| atl_app_name   | NVARCHAR(128)     | es la función APP_NAME() de Azure SQL                        |
| atl_host_name  | NVARCHAR(128)     | es la función HOST_NAME() de Azure SQL                       |
| atl_user       | SYSNAME           | es la función CURRENT_USER de Azure SQL                      |
| atl_action     | VARCHAR(3)        | INS si es INSERT<br />UPD si es UPDATE<br />DEL si es DELETE |

y los demás campos de la tabla original. Los campo "atl_" son obligatorios, pero los demás campos son opcionales y sin PRIMARY KEY ni FOREIGN KEY

b) Crear un trigger, en el mismo esquema de la tabla, del tipo "AFTER INSERT, UPDATE, DELETE" con el formato "trg_iud_{tabla}" donde:
{tabla} es el nombre de la tabla

Este trigger se encarga de llevar los datos de la tabla original a la tabla del tipo "atl" indicando especialmente si fue un INS, UPD o DEL

## Consideraciones para los campos de las tablas de parámetros
El campo llave debe ser {nombre_tabla_singular}_id

El campo descripción del parámetro debe ser {nombre_tabla_singular}_description

Donde {nombre_tabla_singular} es el nombre de la tabla pero en singular

## Consideraciones para los campos de las tablas que no sean parámetros
Los campos son en singular

Si es un campo identificatorio, debe tener esta nomenclatura:

{nombre_tabla_singular}_id

Donde {nombre_tabla_singular} es el nombre de la tabla pero en singular

## Campos de auditoría de todas las tablas
Se deben agregar estos campos obligatorios al final de todas las tablas:

| Campo          | Tipo de Datos     | Explicación                                         |
| -------------- | ----------------- | --------------------------------------------------- |
| author_id      | VARCHAR(16)       |                                                     |
| trace_id       | VARCHAR(32)       | útil para grabar el trace_id de OpenTelemetry       |
| span_id        | VARCHAR(16)       | útil para grabar el span_id de OpenTelemetry        |
| parent_span_id | VARCHAR(16)       | útil para grabar el parent_span_id de OpenTelemetry |
| written_at     | DATETIMEOFFSET(2) |                                                     |

Si se va a poblar alguna tabla en forma inicial se debe poner como author_id a "SYSTEM"