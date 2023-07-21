"use client";

import { makeStyles } from "@/lib/theme";
import { Text } from "@/lib/theme";
import { filterSearch, makeArrayUnique } from "@/lib/utils/helpers";
import { useState, useEffect } from "react";

import { Chip } from "@p4b/ui/components/DataDisplay";
import { EnhancedTable } from "@p4b/ui/components/DataDisplay/EnhancedTable";
import { TextField } from "@p4b/ui/components/Inputs/TextField";
import Modal from "@p4b/ui/components/Modal";
import Banner from "@p4b/ui/components/Surfaces/Banner";
import { Card } from "@p4b/ui/components/Surfaces/Card";
import { Icon, Button, IconButton } from "@p4b/ui/components/theme";

import InviteUser from "./InviteUser";
import UserInfoModal from "./UserInfoModal";

export interface RowsType {
  name: string;
  email: string;
  role: string;
  status: React.ReactNode;
  Added: string;
}

const ManageUsers = () => {
  const { classes } = useStyles();

  // Component States
  const [userInDialog, setUserInDialog] = useState<RowsType | null>();
  const [ismodalVisible, setModalVisible] = useState<boolean>(false);
  const [isAddUser, setAddUser] = useState<boolean>(false);
  const [email, setEmail] = useState("");
  const [searchWord, setSearchWord] = useState<string>("");
  const [rawRows, setRawRows] = useState<RowsType[]>([
    {
      name: "Luca William Silva",
      email: "john.wlsdasadm@gmail.com",
      role: "Admin",
      status: <Chip className={classes.chip} label="Active" variant="Border" color="success" icon="check" />,
      Added: "23 Jun 19",
    },
    {
      name: "Fenix William Silva",
      email: "john.werwxsam@gmail.com",
      role: "Admin",
      status: (
        <Chip className={classes.chip} label="Invite sent" variant="Border" color="main" icon="email" />
      ),
      Added: "23 Jun 19",
    },
    {
      name: "Adam William Silva",
      email: "john.ghjfgpsum@gmail.com",
      role: "Admin",
      status: (
        <Chip className={classes.chip} label="Expired" variant="Border" color="warning" icon="warnOutlined" />
      ),
      Added: "23 Jun 19",
    },
    {
      name: "John William Silva",
      email: "john.zxcsadum@gmail.com",
      role: "Admin",
      status: <Chip className={classes.chip} label="Active" variant="Border" color="success" icon="check" />,
      Added: "23 Jun 19",
    },
    {
      name: "John William Silva",
      email: "john.wawewdssum@gmail.com",
      role: "Admin",
      status: (
        <Chip className={classes.chip} label="Invite sent" variant="Border" color="main" icon="email" />
      ),
      Added: "23 Jun 19",
    },
    {
      name: "John William Silva",
      email: "john.wiuywefipsum@gmail.com",
      role: "Admin",
      status: (
        <Chip className={classes.chip} label="Invite sent" variant="Border" color="main" icon="email" />
      ),
      Added: "23 Jun 19",
    },
  ]);
  const [rows, setRows] = useState<RowsType[]>([]);

  const columnNames = [
    {
      id: "name",
      numeric: false,
      label: "Name",
    },
    {
      id: "email",
      numeric: false,
      label: "E-mail",
    },
    {
      id: "role",
      numeric: false,
      label: "Role",
    },
    {
      id: "status",
      numeric: false,
      label: "Status",
    },
    {
      id: "added",
      numeric: false,
      label: "Added",
    },
  ];

  useEffect(() => {
    console.log(searchWord);
    if (searchWord !== "") {
      let newArr = [
        ...filterSearch(rawRows, "name", searchWord),
        ...filterSearch(rawRows, "email", searchWord),
      ];
      newArr = makeArrayUnique(newArr, "email");
      setRows(newArr);
    } else {
      setRows(rawRows);
    }
  }, [searchWord, rawRows]);

  // Functions

  function sendInvitation() {
    const newUserInvite = {
      name: "Luca William Silva",
      email: email,
      role: "Admin",
      status: (
        <Chip className={classes.chip} label="Invite sent" variant="Border" color="main" icon="email" />
      ),
      Added: "23 Jun 19",
    };
    // rawRows.push(newUserInvite);
    setRawRows([...rawRows, newUserInvite]);
    setSearchWord("");
    setAddUser(false);
  }

  function openModal() {
    setModalVisible(true);
  }

  function closeModal() {
    setUserInDialog(null);
    setModalVisible(false);
  }

  function editUserRole(role: "Admin" | "User" | "Editor", user: RowsType | undefined) {
    if (user) {
      const modifiedUsers = rows.map((row) => {
        if (row.email === user.email) {
          row.role = role;
        }
        return row;
      });
      setRows(modifiedUsers);
    }
  }

  function removeUser(user: RowsType | undefined) {
    if (user) {
      const modifiedUsers = rows.filter((row) => row.email !== user.email);
      setRawRows(modifiedUsers);
      closeModal();
    }
  }

  return (
    <div>
      <div className={classes.container}>
        <div className={classes.head}>
          <Icon
            iconId="user"
            wrapped="circle"
            bgVariant="gray2"
            bgOpacity={0.6}
            iconVariant="secondary"
            size="medium"
          />
          <Text typo="body 1" className={classes.name}>
            Organization name
          </Text>
        </div>
        <div className={classes.search}>
          <TextField
            className={classes.searchInput}
            type="text"
            label="Search"
            size="small"
            onValueBeingTypedChange={({ value }) => setSearchWord(value)}
          />
          <Icon iconId="filter" size="medium" iconVariant="gray" />
          <div style={{ position: "relative" }}>
            <Button onClick={() => setAddUser(true)} className={classes.searchButton}>
              Invite user
            </Button>
            {/* Invite User Dialog */}
            {isAddUser ? (
              <Modal
                width="444px"
                open={isAddUser}
                changeOpen={setAddUser}
                action={
                  <>
                    <Button variant="noBorder" onClick={() => setAddUser(false)}>
                      CANCEL
                    </Button>
                    <Button variant="noBorder" onClick={sendInvitation}>
                      SEND INVITATION
                    </Button>
                  </>
                }
                header={
                  <div className={classes.modalHeader2}>
                    <Text typo="subtitle" className={classes.headerText}>
                      Invite user
                    </Text>
                    <IconButton onClick={() => setAddUser(false)} iconId="close" />
                  </div>
                }>
                <InviteUser setEmail={setEmail} />
              </Modal>
            ) : null}
          </div>
        </div>
      </div>
      <Card noHover={true} className={classes.tableCard}>
        {/* ManageUsers Table */}
        {rows.length ? (
          <EnhancedTable
            rows={rows}
            columnNames={columnNames}
            openDialog={setUserInDialog}
            action={<IconButton type="submit" iconId="moreVert" size="medium" />}
          />
        ) : (
          <Text typo="body 1" color="secondary">
            No results
          </Text>
        )}
      </Card>
      <Banner
        actions={<Button>Subscribe Now</Button>}
        content={
          <Text className={classes.bannerText} typo="body 1">
            Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean
            massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.{" "}
          </Text>
        }
        image="https://s3-alpha-sig.figma.com/img/630a/ef8f/d732bcd1f3ef5d6fe31bc6f94ddfbca8?Expires=1687132800&Signature=aJvQ22UUlmvNjDlrgzV6MjJK~YgohUyT9mh8onGD-HhU5yMI0~ThWZUGVn562ihhRYqlyiR5Rskno84OseNhAN21WqKNOZnAS0TyT3SSUP4t4AZJOmeuwsl2EcgElMzcE0~Qx2X~LWxor1emexxTlWntivbnUeS6qv1DIPwCferjYIwWsiNqTm7whk78HUD1-26spqW3AXVbTtwqz3B8q791QigocHaK9b4f-Ulrk3lsmp8BryHprwgetHlToFNlYYR-SqPFrEeOKNQuEDKH0QzgGv3TX7EfBNL0kgP3Crued~JNth-lIEPCjlDRnFQyNpSiLQtf9r2tH9xIsKA~XQ__&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4"
        imageSide="right"
      />
      {/* Confirm User Removal */}
      <Modal
        width="523px"
        open={userInDialog ? true : false}
        changeOpen={() => setUserInDialog(null)}
        action={
          ismodalVisible ? (
            <>
              <Button onClick={closeModal} variant="noBorder">
                CANCEL
              </Button>
              <Button onClick={() => removeUser(userInDialog ? userInDialog : undefined)} variant="noBorder">
                CONFIRM
              </Button>
            </>
          ) : (
            <Button onClick={() => openModal()} variant="noBorder">
              REMOVE USER
            </Button>
          )
        }
        header={
          ismodalVisible ? (
            <Text className={classes.modalHeader} typo="subtitle">
              <Icon iconId="warn" iconVariant="warning" /> Attention
            </Text>
          ) : (
            <div className={classes.modalHeader2}>
              <Text typo="subtitle" className={classes.headerText}>
                {userInDialog?.name}
              </Text>
              <IconButton onClick={() => setUserInDialog(null)} iconId="close" />
            </div>
          )
        }>
        <UserInfoModal
          ismodalVisible={ismodalVisible}
          userInDialog={userInDialog ? userInDialog : false}
          editUserRole={editUserRole}
        />
      </Modal>
    </div>
  );
};

const useStyles = makeStyles({ name: { ManageUsers } })((theme) => ({
  bannerText: {
    color: "white",
    "@media (max-width: 1268px)": {
      fontSize: "14px",
    },
  },
  name: {
    fontWeight: "bold",
  },
  head: {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing(2),
    marginBottom: theme.spacing(3),
    paddingTop: theme.spacing(2),
    paddingBottom: theme.spacing(2),
  },
  search: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: theme.spacing(4),
    marginBottom: theme.spacing(3),
  },
  searchButton: {
    width: "131px",
  },
  container: {
    padding: `0px ${theme.spacing(3)}px`,
    marginBottom: theme.spacing(2),
  },
  searchInput: {
    flexGrow: "1",
  },
  tableCard: {
    padding: theme.spacing(3),
    marginBottom: theme.spacing(5),
  },
  modalHeader: {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing(1),
  },
  modalHeader2: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
  },
  chip: {
    "& .mui-6od3lo-MuiChip-label": {
      padding: "4px",
    },
  },
  headerText: {
    fontWeight: "normal",
  },
}));

export default ManageUsers;
