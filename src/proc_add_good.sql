delimiter $$

drop procedure proc_add_good$$

create procedure proc_add_good(
    in i_store_id int(10) unsigned,
    in i_goods_name varchar(255),
    in i_description varchar(255),
    in i_default_image varchar(255),
    in i_price decimal(10,2),
    out o_retcode int)
begin
    declare v_good_id int(10) unsigned;
    declare pos int(10);

    select goods_id into v_good_id from ecm_goods where goods_name=i_goods_name;

    set o_retcode = -1;

    if v_good_id is null then
       insert into ecm_goods(store_id, goods_name, type, description, default_image, price) values (i_store_id, i_goods_name, 'unfetch', i_description, i_default_image, i_price);
       set o_retcode = 0;
    else
       set o_retcode = 1;
    end if;

    select i_description, i_goods_name, o_retcode;

end$$

delimiter ;
