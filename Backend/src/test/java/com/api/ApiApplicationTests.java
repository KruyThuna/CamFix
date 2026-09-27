package com.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import com.api.entity.*;
import static org.junit.jupiter.api.Assertions.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
	"spring.datasource.url=jdbc:h2:mem:camfix-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
	"spring.datasource.driver-class-name=org.h2.Driver",
	"spring.datasource.username=sa",
	"spring.datasource.password=",
	"spring.jpa.hibernate.ddl-auto=none"
})
class ApiApplicationTests {

	@Autowired
	private WebApplicationContext context;

	@Autowired private EntityManager entities;
	@Autowired private JdbcTemplate jdbc;

	@Test
	void contextLoads() {
	}

	@Test
	void openApiDocumentationIsAvailable() throws Exception {
		MockMvcBuilders.webAppContextSetup(context).build()
			.perform(get("/v3/api-docs"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.openapi").exists())
			.andExpect(jsonPath("$.paths").isMap());
	}

	@Test
	@Transactional
	void existingDatabaseColumnNamesSupportAddressAndCallInserts() {
		jdbc.execute("CREATE TABLE IF NOT EXISTS user_addresses (AddressID BIGINT AUTO_INCREMENT PRIMARY KEY, UserID BIGINT NOT NULL, Address_Name VARCHAR(255) NOT NULL, Address_Line VARCHAR(255) NOT NULL, city VARCHAR(255), province VARCHAR(255), latitude DOUBLE, longitude DOUBLE, Is_Default BOOLEAN NOT NULL DEFAULT FALSE)");
		jdbc.execute("CREATE TABLE IF NOT EXISTS technician_addresses (AddressID BIGINT AUTO_INCREMENT PRIMARY KEY, TechnicianID BIGINT, technician_id BIGINT, business_name VARCHAR(255), Address_line VARCHAR(255) NOT NULL, city VARCHAR(255), province VARCHAR(255), latitude DOUBLE, longitude DOUBLE, Is_default BOOLEAN NOT NULL DEFAULT FALSE, create_at TIMESTAMP NOT NULL, update_at TIMESTAMP NOT NULL)");
		jdbc.execute("CREATE TABLE IF NOT EXISTS call_history (CallID BIGINT AUTO_INCREMENT PRIMARY KEY, CallerID BIGINT, TechnicianID BIGINT, user_id BIGINT NOT NULL, technician_id BIGINT NOT NULL, call_status VARCHAR(20) NOT NULL, Started_At TIMESTAMP, Ended_At TIMESTAMP, Duration_Seconds INT, Created_At TIMESTAMP NOT NULL)");
		var address = UserAddress.builder().userId(1L).address_Name("Home")
			.address_Line("Street 1").isDefault(true).build();
		entities.persist(address);
		var technicianAddress = TechnicianAddresses.builder().technicianId(1L)
			.addressLine("Street 2").isDefault(false).build();
		entities.persist(technicianAddress);
		var call = new CallHistory();
		call.setUser(entities.getReference(Users.class, 1L));
		call.setTechnician(entities.getReference(Technician.class, 1L));
		call.setCallStatus("ONGOING");
		entities.persist(call);
		entities.flush();
		entities.clear();
		assertEquals("Street 1", entities.find(UserAddress.class, address.getId()).getAddress_Line());
		assertEquals(Boolean.TRUE, jdbc.queryForObject("SELECT Is_Default FROM user_addresses WHERE AddressID = ?", Boolean.class, address.getId()));
		assertEquals("Street 2", entities.find(TechnicianAddresses.class, technicianAddress.getAddressId()).getAddressLine());
		assertEquals("ONGOING", entities.find(CallHistory.class, call.getCallId()).getCallStatus());
	}

}
