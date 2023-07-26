import { useState, useEffect } from "react";
import axios from "axios";
import useSWR from "swr";
import { filterSearch, makeArrayUnique } from "@/lib/utils/helpers";
import type { User } from "manage-users-dashboard";

// Get all users in order to manage them
export const useUsersData = (searchWord?: string) => {
  const UsersFetcher = (url: string) => {
    return axios(url).then((res) => res.data);
  };

  const { data, error, isLoading } = useSWR("/api/dashboard/organization", UsersFetcher);
  const [rawRows, setRawRows] = useState<User[]>([]);
  const [rows, setRows] = useState<User[]>([]);

  useEffect(() => {
    setRawRows(data || []);
  }, [data]);

  useEffect(() => {
    if (searchWord && searchWord !== "") {
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

  return { rawRows, setRawRows, setRows, rows, isLoading, error };
};

// Invite a user dialog
export const useInviteUserDialog = () => {
  const [isAddUser, setAddUser] = useState(false);
  const [email, setEmail] = useState("");

  const openInviteDialog = () => setAddUser(true);
  const closeInviteDialog = () => setAddUser(false);

  return { isAddUser, openInviteDialog, closeInviteDialog, email, setEmail };
};

// Remove user dialog
export const useUserRemovalDialog = () => {
  const [userInDialog, setUserInDialog] = useState<User | null>(null);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);

  const openUserRemovalDialog = (user: User) => {
    setModalVisible(true);
    setUserInDialog(user);
  };

  const closeUserRemovalDialog = () => {
    setModalVisible(false);
    setUserInDialog(null);
  };

  const setTheUserInDialog = (user: User) => {
    setUserInDialog(user)
  }

  return { userInDialog, isModalVisible, openUserRemovalDialog, closeUserRemovalDialog, setTheUserInDialog };
};