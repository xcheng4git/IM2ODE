!     
! File:   init_mod.F90
! Author: zyy
!
! Created on 2013年4月20日, 下午4:19
!

module init_mod
    use parameters, only : spacegroup_log
    use spacegroup_data, only : init_spg
    implicit none
    contains
    subroutine init_run()
        use kinds
        use parameters, only : pool, population
        implicit none
        integer(i4b) :: i
        real(dp) :: inf = 1e8
        call init_rand()
        open(1224,file="results/run_de.out")
        write(1224, *) "start de searching ......"
        call read_input()
        call write_input()
        spacegroup_log = 0
        
        do i = 1, population
            pool(i) % energy = inf
            pool(i) % hardness = inf
            pool(i) % Eg_id = inf
            pool(i) % Eg_d = inf
        end do
        
        call init_spg
    end subroutine init_run
    
    subroutine init_rand()
        use kinds
        integer(i4b) :: i, n, clock
        real(dp) :: x, y, time
        integer(i4b), dimension(:), allocatable :: seed
        call cpu_time(time)
        call random_seed(size = n)
        allocate(seed(n))
        call system_clock(count=clock)
        seed = clock + 37 * (/(i - 1, i = 1, n)/)
        call random_seed(put = seed)
        deallocate(seed)
    end subroutine init_rand
    
    subroutine read_input()
        use parameters, only : sys_name, num_species, num_ele, name_element, atom_dis, volumn
        use parameters, only : population, max_step, de_ratio, symmetry
        use parameters, only : mode, hardness, rcut, ionicity
        use parameters, only : ESflag, ES_mod, ES_Eg, Es_opt
        use kinds
        implicit none
        
        integer(i4b) :: n, i, j, k, line, f1, lth
        character(len=40) :: nametag(200), number(200)
        character(len=200) :: strin(200), strtmp
        logical :: flag
        
        inquire(file="de.in", exist = flag)
        if(.not. flag) then
            write(1224, *) "no de.in"
            stop
        end if
        open(unit = 5111, file = "de.in", status = "old")
        line = 0
        f1 = 0
        do while(.true.)
            line = line + 1
            read(5111, fmt="(A200)", iostat=f1) strin(line)
            if(f1 /= 0) exit
        end do
        close(5111)
        
        n = 0
        do i = 1, line
            if(len(trim(strin(i))) == 0 .or. len(trim(strin(i))) == 1) then
                continue
            else
                read(strin(i), *) strtmp
                if(strtmp /= '#') then
                    lth = index(strin(i), '=')
                    if(lth /= 0) then
                        n = n + 1
                        read(strin(i)(:lth-1), "(A40)")nametag(n)
                        read(strin(i)(lth+1:), "(A40)")number(n)
                    end if
                end if
            end if
        end do
        
        call find(nametag, 'SystemName', i)
        if(i == 0) then
            write(1224, *) "Input SystemName"
            sys_name = "zyy"
        else
            read(number(i), *) sys_name
        end if
        
        call find(nametag, 'NumberOfSpecies', i)
        if(i == 0) then
            write(1224, *) "Input NumberOfSpecies"
            num_species = 1
        else
            read(number(i), *) num_species
        end if
        
        call find(nametag, "NumberOfElements", i)
        if(i == 0) then
            write(1224, *) "Input NumberOfElements"
            num_ele(1) = 2
        else
            read(number(i), *) (num_ele(j), j = 1, num_species)
        end if
        
        call find(nametag, "NameOfElements", i)
        if(i == 0) then
            write(1224, *) "Input NameOfElements"
            name_element(1) = "X"
        else
            read(number(i), *) (name_element(j), j = 1, num_species)
        end if
        
        call find(nametag, "Volumn", i)
        if(i == 0) then
            write(1224, *) "Input Volumn"
            volumn = 10
        else
            read(number(i), *) volumn
        end if
        
        call find(nametag, "DistanceOfAtom", i)
        if(i == 0) then
            write(1224, *) "Input DistanceOfAtom"
        else
            do j = 1, num_species
                read(number(i + j), *) (atom_dis(j, k), k = 1, num_species)
            end do
        end if
        
        call find(nametag, "Population", i)
        if(i == 0) then
            write(1224, *) "Input Population"
            population = 10
        else
            read(number(i), *) population
        end if
        
        call find(nametag, "MaxStep", i)
        if(i == 0) then
            write(1224, *) "Input MaxStep"
            max_step = 10
        else
            read(number(i), *) max_step
        end if
        
        call find(nametag, "De_ratio", i)
        if(i == 0) then
            write(1224, *) "Input De_ratio"
            de_ratio = 0.8
        else
            read(number(i), *) de_ratio
        end if
        
        call find(nametag, "Symmetry", i)
        if(i == 0) then
            symmetry = .false.
        else
            read(number(i), *) symmetry
        end if
        
        call find(nametag, "Multi-Objective", i)
        if(i == 0) then
            mode = .false.
        else
            read(number(i), *) mode
        end if
        
        call find(nametag, "hardness", i)
        if(i == 0) then
            hardness = .false.
        else
            read(number(i), *) hardness
            
            call find(nametag, "rcut", i)
            if(i == 0) then
                write(1224,*) "Input rcut"
                rcut = 1.5
            else
                read(number(i), *) rcut
            end if
            
            call find(nametag, "ionicity", i)
            if(i == 0) then
                write(1224,*) "Input ionicity"
                ionicity = 0.0
            else
                read(number(i), *) ionicity
            end if
        end if
        
        call find(nametag, "ESflag", i)
        if(i == 0) then
            ESflag = .false.
        else
            read(number(i), *) ESflag
            
            call find(nametag, "ES_mod", i)
            if(i == 0) then
                write(1224, *) "Input ES_mod"
                ES_mod = 6
            else
                read(number(i), *) ES_mod
            end if
            
            call find(nametag, "ES_Eg", i)
            if(i == 0) then
                write(1224, *) "Input ES_Eg"
                ES_Eg = 1.0
            else
                read(number(i), *) ES_Eg
            end if
            
            call find(nametag, "ES_opt", i)
            if(i == 0) then
                write(1224, *) "Inout ES_pot"
                ES_opt = 1.2
            else
                read(number(i), *) ES_opt
            end if
        end if
        
    end subroutine read_input
    
    subroutine find(a, b, i)
        use kinds
        character(len=40) :: a(200)
        character(len=*) :: b
        integer(i4b) :: i,j
        i = 0
        do j = 1, 200
            if(trim(a(j)) == b) then
                i = j
                exit
            end if
        end do
    end subroutine find
    
    subroutine write_input()
        use kinds
        use parameters
        implicit none
        integer(i4b) :: i, j
        write(1224, *) "---write input parameters---"
        write(1224, *) "system name: ", sys_name
        write(1224, *) "NumberOfSpecies: ", num_species
        write(1224, *) "NumberOfElements: ", (num_ele(i), i = 1, num_species)
        write(1224, *) "NameOfElements: ", (' '//name_element(i), i = 1, num_species)
        write(1224, *) "Volumn: ", volumn
        write(1224, *) "DistanceOfAtom: "
        do i = 1, num_species
            write(1224, *) (atom_dis(i, j), j = 1, num_species)
        end do
        write(1224, *) "Population: ", population
        write(1224, *) "MaxStep: ", max_step
        write(1224, *) "---end write input---"
    end subroutine write_input
        
end module init_mod
